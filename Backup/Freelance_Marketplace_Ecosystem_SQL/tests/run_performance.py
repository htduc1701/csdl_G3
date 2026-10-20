#!/usr/bin/env python3
"""Isolated scale fixture: only creates mini_upwork_perf; refuses to overwrite it."""
import os,time,json,statistics
from pathlib import Path
import pymysql
P=Path(__file__).resolve().parents[1]
c=pymysql.connect(host=os.getenv('DB_HOST','127.0.0.1'),port=int(os.getenv('DB_PORT','3307')),user=os.getenv('DB_USER','root'),password=os.getenv('DB_PASSWORD',''),autocommit=True)
cur=c.cursor();cur.execute('CREATE DATABASE mini_upwork_perf')
def script(path):
 delimiter=';';buf=''
 for l in path.read_text().splitlines():
  if l.strip().startswith('DELIMITER '):delimiter=l.split()[1];continue
  if l.lstrip().startswith('--'):continue
  buf+=l+'\n'
  if buf.rstrip().endswith(delimiter):
   s=buf.rstrip()[:-len(delimiter)].strip().replace('mini_upwork','mini_upwork_perf');buf=''
   if s:cur.execute(s)
try:
 for f in ['01_schema.sql','02_triggers.sql','03_views_indexes.sql']:script(P/'sql'/f)
 cur.execute("INSERT INTO users (user_id,email,full_name,password_hash,user_type) VALUES (1,'client@example.test','Demo','DEMO','CLIENT'),(4,'f4@example.test','Demo','DEMO','FREELANCER'),(5,'f5@example.test','Demo','DEMO','FREELANCER')")
 cur.execute("INSERT INTO job_categories (category_id,category_name) VALUES (1,'Demo')")
 cur.executemany("INSERT INTO jobs (job_id,client_id,category_id,title,description,budget_max) VALUES (%s,1,1,%s,'Demo',%s)",[(i,f'Scale job {i}',i) for i in range(1,5001)])
 cur.executemany("INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (%s,%s,100,'Demo',20)",[(i,f) for i in range(1,5001) for f in (4,5)])
 cur.execute('ANALYZE TABLE jobs, proposals');cur.fetchall()
 results=[]
 for label,hint in [('index_allowed',''),('index_ignored','IGNORE INDEX (ix_jobs_status_budget)')]:
  sql=f"SELECT job_id,budget_max FROM jobs {hint} WHERE status='OPEN' AND budget_max>=4800 ORDER BY budget_max DESC LIMIT 20"
  times=[]
  for i in range(31):
   t=time.perf_counter();cur.execute(sql);rows=cur.fetchall();times.append((time.perf_counter()-t)*1000)
  cur.execute('EXPLAIN FORMAT=JSON '+sql);plan=json.loads(cur.fetchone()[0])
  cur.execute('EXPLAIN ANALYZE '+sql);analyze=cur.fetchone()[0]
  results.append(dict(label=label,sql=sql,median_ms=statistics.median(times[1:]),actual=rows,explain=plan,explain_analyze=analyze))
 assert results[0]['actual']==results[1]['actual']
 cur.execute('SELECT VERSION()');version=cur.fetchone()[0]
 P.joinpath('evidence/performance_results.json').write_text(json.dumps(dict(version=version,jobs=5000,proposals=10000,warmup=1,measured_runs=30,results=results,identical_results=True),indent=2,default=str))
 print([(r['label'],r['median_ms']) for r in results])
finally:cur.execute('DROP DATABASE mini_upwork_perf');c.close()
