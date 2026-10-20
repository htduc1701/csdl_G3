"""Run only on a dedicated disposable instance. Writes evidence; no DROP DATABASE."""
import argparse, base64, datetime, decimal, hashlib, importlib.util, json, os
from pathlib import Path
import secrets, statistics, threading, time, urllib.request, urllib.parse, urllib.error, re
import pymysql
BASE=Path(__file__).resolve().parents[1]
OUT=BASE.parent
EVIDENCE=Path(os.getenv('G3_EVIDENCE',str(OUT/'evidence')))
EVIDENCE.mkdir(parents=True,exist_ok=True)
CONFIG=dict(host=os.getenv('DB_HOST','127.0.0.1'),port=int(os.getenv('DB_PORT','33370')),
 user=os.getenv('DB_USER','root'),password=os.getenv('DB_PASSWORD',''),autocommit=True,charset='utf8mb4')
results=[]
def connect(user=None,password=None):
 c=pymysql.connect(**(CONFIG|({'user':user,'password':password} if user else {})))
 with c.cursor() as cur:cur.execute('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED');cur.execute('USE mini_upwork')
 return c
def script(c,path):
 delimiter=';';buf=''
 for line in path.read_text(encoding='utf-8').splitlines():
  if line.strip().startswith('DELIMITER '):delimiter=line.split()[1];continue
  if line.lstrip().startswith('--'):continue
  buf+=line+'\n'
  if buf.rstrip().endswith(delimiter):
   sql=buf.rstrip()[:-len(delimiter)].strip();buf=''
   if sql:
    with c.cursor() as cur:
     cur.execute(sql)
     while cur.nextset():pass
 if buf.strip():raise RuntimeError('Unterminated SQL: '+str(path))
def record(name,passed,**kw):
 results.append(dict(id=name,passed=bool(passed),**kw));print(name,'PASS' if passed else 'FAIL',flush=True)
def check(c,name,sql,expected=0,params=None):
 if not sql.lstrip().upper().startswith('CALL '):c.begin()
 actual=0;message='accepted'
 try:
  with c.cursor() as cur:cur.execute(sql,params)
 except pymysql.MySQLError as e:actual=e.args[0];message=str(e)
 finally:c.rollback()
 record(name,actual==expected,sql=sql,expected_error=expected,actual_error=actual,message=message)
def scalar(c,sql):
 with c.cursor() as cur:cur.execute(sql);return cur.fetchone()[0]
def run(fresh=False):
 if fresh:
  c=pymysql.connect(**CONFIG)
  with c.cursor() as cur:
   cur.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='mini_upwork'")
   if cur.fetchone()[0]:raise RuntimeError('Refusing installation: mini_upwork has tables. Use a fresh isolated instance.')
  script(c,BASE/'INSTALL_DATABASE.sql');c.close()
 c=connect()
 version=scalar(c,'SELECT VERSION()')
 before={t:scalar(c,'SELECT COUNT(*) FROM '+t) for t in ['users','clients','freelancers','skills','freelancer_skills','job_categories','jobs','proposals','contracts','milestones','payments','contract_reviews']}
 metadata={}
 with c.cursor(pymysql.cursors.DictCursor) as cur:
  cur.execute("SELECT table_name,column_name,column_type,is_nullable,column_default,column_key,extra,generation_expression FROM information_schema.columns WHERE table_schema='mini_upwork' ORDER BY table_name,ordinal_position")
  metadata['columns']=cur.fetchall()
  cur.execute("SELECT table_name,column_name,constraint_name,referenced_table_name,referenced_column_name FROM information_schema.key_column_usage WHERE table_schema='mini_upwork' ORDER BY table_name,constraint_name,ordinal_position")
  metadata['keys']=cur.fetchall()
  cur.execute("SELECT tc.table_name,cc.constraint_name,cc.check_clause FROM information_schema.table_constraints tc JOIN information_schema.check_constraints cc ON cc.constraint_schema=tc.constraint_schema AND cc.constraint_name=tc.constraint_name WHERE tc.table_schema='mini_upwork'")
  metadata['checks']=cur.fetchall()
  cur.execute("SELECT trigger_name,event_manipulation,event_object_table,action_timing FROM information_schema.triggers WHERE trigger_schema='mini_upwork'");metadata['triggers']=cur.fetchall()
  cur.execute("SELECT routine_name FROM information_schema.routines WHERE routine_schema='mini_upwork'");metadata['procedures']=cur.fetchall()
 (EVIDENCE/'schema_metadata.json').write_text(json.dumps(metadata,indent=2,default=str),encoding='utf-8')
 (EVIDENCE/'dataset_counts.json').write_text(json.dumps(dict(engine=version,counts=before,total=sum(before.values()),phase='after fresh install before tests'),indent=2),encoding='utf-8')
 tests=[
 ('subtype_disjoint',"INSERT INTO freelancers(freelancer_id) VALUES(1)",1644),
 ('subtype_retained','DELETE FROM clients WHERE client_id=1',1644),
 ('user_type_immutable',"UPDATE users SET user_type='FREELANCER' WHERE user_id=1",1644),
 ('duplicate_email',"INSERT INTO users(email,full_name,password_hash,user_type) SELECT email,'x','x','CLIENT' FROM users WHERE user_id=1",1062),
 ('invalid_job_category',"INSERT INTO jobs(client_id,category_id,title,description) VALUES(1,999999,'x','x')",1452),
 ('invalid_budget',"INSERT INTO jobs(client_id,category_id,title,description,budget_min,budget_max) VALUES(1,1,'x','x',100,1)",3819),
 ('duplicate_proposal',"INSERT INTO proposals(job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES(6,6,1,'x',1)",1062),
 ('invalid_proposal_amount',"INSERT INTO proposals(job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES(7,4,0,'x',1)",3819),
 ('confirmation_without_selection',"UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=11",1644),
 ('contract_parties_immutable','UPDATE contracts SET client_id=2 WHERE contract_id=1',1644),
 ('contract_terms_immutable','UPDATE contracts SET total_amount=2000 WHERE contract_id=1',1644),
 ('milestone_overflow',"INSERT INTO milestones(contract_id,title,amount) VALUES(1,'x',1)",1644),
 ('milestone_skip',"UPDATE milestones SET status='APPROVED' WHERE milestone_id=8",1644),
 ('started_terms_immutable','UPDATE milestones SET amount=1 WHERE milestone_id=1',1644),
 ('payment_before_approval',"INSERT INTO payments(milestone_id,payment_method) VALUES(2,'PAYPAL')",1644),
 ('duplicate_successful_payment',"INSERT INTO payments(milestone_id,payment_method,payment_status) VALUES(1,'PAYPAL','PAID')",1062),
 ('failed_payment_retry',"INSERT INTO payments(milestone_id,payment_method,payment_status) VALUES(9,'PAYPAL','PAID')",0),
 ('invalid_payment_method',"INSERT INTO payments(milestone_id,payment_method) VALUES(9,'INVALID')",3819),
 ('terminal_payment_immutable',"UPDATE payments SET payment_status='FAILED' WHERE payment_id=2",1644),
 ('payment_history_retained','DELETE FROM payments WHERE payment_id=1',1644),
 ('review_before_completion',"INSERT INTO contract_reviews(contract_id,rating) VALUES(1,5)",1644),
 ('incomplete_contract_cannot_close',"UPDATE contracts SET status='COMPLETED' WHERE contract_id=1",1644),
 ]
 for name,sql,expected in tests:check(c,name,sql,expected)
 review_contract=scalar(c,'SELECT MIN(contract_id) FROM contract_reviews')
 check(c,'duplicate_review',f'INSERT INTO contract_reviews(contract_id,rating) VALUES({review_contract},5)',1062)
 check(c,'review_immutable',f'UPDATE contract_reviews SET rating=1 WHERE contract_id={review_contract}',1644)
 check(c,'review_retained',f'DELETE FROM contract_reviews WHERE contract_id={review_contract}',1644)
 # Test rating CHECK on a completed contract after rollback-removing a seeded row is impossible by design.
 # A new fully paid workflow below creates a review-free completed contract.
 names=['client_1','client_2','freelancer_4','freelancer_5','payment_service','report_reader']
 passwords={n:secrets.token_urlsafe(24) for n in names}
 with c.cursor() as cur:
  for name in names:
   cur.execute(f"ALTER USER '{name}'@'localhost' IDENTIFIED BY %s ACCOUNT UNLOCK",(passwords[name],))
 actors={n:connect(n,passwords[n]) for n in names}
 def call(name,proc,args):
  with actors[name].cursor() as cur:
   cur.callproc(proc,args)
   while cur.nextset():pass
 check(actors['client_1'],'rbac_no_direct_write',"UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=11",1142)
 check(actors['report_reader'],'rbac_no_password_hash','SELECT password_hash FROM users',1142)
 check(actors['client_1'],'rbac_no_record_payment',"CALL sp_record_payment(1,9,'PAYPAL','PAID')",1370)
 check(actors['client_1'],'actor_spoofing',"CALL sp_select_proposal(2,11)",1644)
 check(actors['client_2'],'outside_contract_review',"CALL sp_submit_review(2,1,5,'x')",1644)
 check(actors['freelancer_4'],'freelancer_cannot_review',f"CALL sp_submit_review(4,{review_contract},5,'x')",1370)
 check(actors['client_1'],'null_actor',"CALL sp_select_proposal(NULL,11)",1644)
 call('client_1','sp_post_job',[1,1,'G3 integration workflow','Created by the verification suite',100,100,None])
 job=scalar(c,"SELECT MAX(job_id) FROM jobs WHERE title='G3 integration workflow'")
 call('freelancer_4','sp_submit_proposal',[4,job,100,'Verification proposal',30])
 proposal=scalar(c,f'SELECT proposal_id FROM proposals WHERE job_id={job}')
 call('client_1','sp_select_proposal',[1,proposal]);call('freelancer_4','sp_confirm_proposal',[4,proposal])
 contract=scalar(c,f'SELECT contract_id FROM contracts WHERE proposal_id={proposal}')
 record('mutual_consent_creates_one_contract',scalar(c,f'SELECT COUNT(*) FROM contracts WHERE proposal_id={proposal}')==1)
 call('client_1','sp_add_milestone',[1,contract,'Verified delivery',100,None])
 milestone=scalar(c,f'SELECT milestone_id FROM milestones WHERE contract_id={contract}')
 call('freelancer_4','sp_advance_milestone',[4,milestone,'IN_PROGRESS'])
 call('freelancer_4','sp_advance_milestone',[4,milestone,'COMPLETED'])
 check(actors['freelancer_4'],'freelancer_cannot_approve',f"CALL sp_advance_milestone(4,{milestone},'APPROVED')",1644)
 call('client_1','sp_advance_milestone',[1,milestone,'APPROVED'])
 call('payment_service','sp_record_payment',[1,milestone,'PAYPAL','FAILED'])
 call('payment_service','sp_record_payment',[1,milestone,'PAYPAL','PAID'])
 call('client_1','sp_complete_contract',[1,contract])
 check(actors['client_1'],'rating_above_domain',f"CALL sp_submit_review(1,{contract},6,'x')",3819)
 check(actors['client_1'],'rating_below_domain',f"CALL sp_submit_review(1,{contract},0,'x')",3819)
 call('client_1','sp_submit_review',[1,contract,5,'Verified workflow review'])
 record('end_to_end_payment_and_review',scalar(c,f'SELECT rating FROM contract_reviews WHERE contract_id={contract}')==5)
 record('completed_job_synced',scalar(c,f"SELECT COUNT(*) FROM jobs WHERE job_id={job} AND status='COMPLETED'")==1)
 record('normalized_payment_columns',scalar(c,"SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='mini_upwork' AND table_name='payments' AND column_name IN ('payer_id','payee_id','amount')")==0)
 record('payment_view_derives_transfer',scalar(c,f'SELECT COUNT(*) FROM v_payment_details WHERE milestone_id={milestone} AND payer_id=1 AND payee_id=4 AND amount=100')==2)
 # Independent aggregate oracle on base contracts/reviews.
 with c.cursor() as cur:
  cur.execute('SELECT c.freelancer_id,COUNT(*),ROUND(AVG(r.rating),2) FROM contracts c JOIN contract_reviews r ON r.contract_id=c.contract_id GROUP BY c.freelancer_id');oracle=cur.fetchall()
  cur.execute('SELECT freelancer_id,rating_count,average_rating FROM v_freelancer_ratings WHERE rating_count>0');actual=cur.fetchall()
 record('rating_aggregate_oracle',sorted(oracle)==sorted(actual),expected=oracle,actual=actual)
 record('unrated_mean_is_null',scalar(c,'SELECT COUNT(*) FROM v_freelancer_ratings WHERE rating_count=0 AND average_rating IS NOT NULL')==0)
 record('no_payment_fanout',scalar(c,"SELECT SUM(amount) FROM v_payment_details WHERE payment_status='PAID'")==scalar(c,'SELECT SUM(paid_amount) FROM v_client_spend'))
 # Two simultaneous inserts for a fresh active contract serialize on parent lock.
 with c.cursor() as cur:
  cur.execute("INSERT INTO jobs(client_id,category_id,title,description) VALUES(1,1,'Concurrency','test')");j=cur.lastrowid
  cur.execute("INSERT INTO proposals(job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES(%s,4,100,'test',30)",(j,));p=cur.lastrowid
  cur.execute("UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE proposal_id=%s",(p,));cur.execute("UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=%s",(p,))
 ct=scalar(c,f'SELECT contract_id FROM contracts WHERE proposal_id={p}')
 barrier=threading.Barrier(2);outcomes=[]
 def concurrent():
  cc=connect();barrier.wait()
  try:
   with cc.cursor() as cur:cur.execute("INSERT INTO milestones(contract_id,title,amount) VALUES(%s,'parallel',60)",(ct,))
   outcomes.append(0)
  except pymysql.MySQLError as e:outcomes.append(e.args[0])
  finally:cc.close()
 threads=[threading.Thread(target=concurrent) for _ in range(2)]
 for t in threads:t.start()
 for t in threads:t.join(15)
 record('concurrent_budget_serialization',sorted(outcomes)==[0,1644],outcomes=outcomes)
 record('concurrent_budget_invariant',scalar(c,f'SELECT SUM(amount) FROM milestones WHERE contract_id={ct}')==60)
 invariants={
 'total_disjoint_subtype':"SELECT COUNT(*) FROM users u LEFT JOIN clients c ON c.client_id=u.user_id LEFT JOIN freelancers f ON f.freelancer_id=u.user_id WHERE (c.client_id IS NOT NULL)+(f.freelancer_id IS NOT NULL)<>1 OR (u.user_type='CLIENT' AND c.client_id IS NULL) OR (u.user_type='FREELANCER' AND f.freelancer_id IS NULL)",
 'unique_proposal_pair':'SELECT COUNT(*) FROM (SELECT job_id,freelancer_id FROM proposals GROUP BY job_id,freelancer_id HAVING COUNT(*)>1) x',
 'unique_selected_proposal':"SELECT COUNT(*) FROM (SELECT job_id FROM proposals WHERE status IN ('CLIENT_ACCEPTED','CONFIRMED') GROUP BY job_id HAVING COUNT(*)>1) x",
 'confirmed_contract_exists':"SELECT COUNT(*) FROM proposals p LEFT JOIN contracts c ON c.proposal_id=p.proposal_id WHERE p.status='CONFIRMED' AND c.contract_id IS NULL",
 'contract_parties_match':'SELECT COUNT(*) FROM contracts c JOIN proposals p ON p.proposal_id=c.proposal_id JOIN jobs j ON j.job_id=p.job_id WHERE c.client_id<>j.client_id OR c.freelancer_id<>p.freelancer_id OR c.total_amount<>p.proposed_amount',
 'milestone_budget':'SELECT COUNT(*) FROM (SELECT c.contract_id FROM contracts c JOIN milestones m ON m.contract_id=c.contract_id GROUP BY c.contract_id,c.total_amount HAVING SUM(m.amount)>c.total_amount) x',
 'payment_requires_approved':"SELECT COUNT(*) FROM payments p JOIN milestones m ON m.milestone_id=p.milestone_id WHERE m.status<>'APPROVED'",
 'unique_paid_attempt':"SELECT COUNT(*) FROM (SELECT milestone_id FROM payments WHERE payment_status='PAID' GROUP BY milestone_id HAVING COUNT(*)>1) x",
 'milestone_date_bounds':'SELECT COUNT(*) FROM milestones m JOIN contracts c ON c.contract_id=m.contract_id WHERE m.due_date<c.start_date OR m.due_date>c.end_date',
 'review_completion':"SELECT COUNT(*) FROM contract_reviews r JOIN contracts c ON c.contract_id=r.contract_id WHERE c.status<>'COMPLETED' OR r.rating NOT BETWEEN 1 AND 5",
 }
 for name,sql in invariants.items():record('invariant_'+name,scalar(c,sql)==0,expected=0,actual=scalar(c,sql),sql=sql)
 # Query outputs and measured warm runtimes; complete result set counts, 5-row preview.
 raw=(BASE/'sql/06_queries.sql').read_text(encoding='utf-8')
 chunks=re.split(r'-- Q-(\d+) ([^\n]+)\n',raw);queries=[]
 for i in range(1,len(chunks),3):
  qid,title,sql=chunks[i:i+3];sql=sql.strip().rstrip(';')
  with c.cursor() as cur:
   cur.execute(sql);rows=cur.fetchall();cols=[d[0] for d in cur.description]
   timings=[]
   for _ in range(5):
    t=time.perf_counter();cur.execute(sql);cur.fetchall();timings.append((time.perf_counter()-t)*1000)
   cur.execute('EXPLAIN '+sql);plan=cur.fetchall()
  queries.append(dict(id='Q-'+qid,title=title,sql=sql,row_count=len(rows),columns=cols,preview=rows[:5],median_ms=statistics.median(timings),plan=plan))
 record('all_15_queries_execute',len(queries)==15)
 # Real HTTP request authenticates native client and renders DB rows.
 spec=importlib.util.spec_from_file_location('g3demo',OUT/'app/server.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
 os.environ['DB_PORT']=str(CONFIG['port']);os.environ['DB_HOST']=CONFIG['host']
 server=mod.ThreadingHTTPServer(('127.0.0.1',0),mod.Handler)
 thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
 url=f'http://127.0.0.1:{server.server_port}/'
 auth='Basic '+base64.b64encode(('client_1:'+passwords['client_1']).encode()).decode()
 page=urllib.request.urlopen(urllib.request.Request(url,headers={'Authorization':auth})).read().decode()
 record('http_reads_database', 'G3 integration workflow' in page and 'v_freelancer_ratings' in page)
 token=re.search(r'name="csrf" value="([a-f0-9]+)"',page)[1]
 data=urllib.parse.urlencode(dict(csrf=token,action='post_job',actor=1,category=1,title='HTTP verified job',description='HTTP integration',min_budget=10,max_budget=20,deadline='')).encode()
 response=urllib.request.urlopen(urllib.request.Request(url,data=data,headers={'Authorization':auth})).read().decode()
 record('http_writes_database', 'Action committed' in response and scalar(c,"SELECT COUNT(*) FROM jobs WHERE title='HTTP verified job'")==1)
 try:
  urllib.request.urlopen(urllib.request.Request(url,data=b'action=post_job',headers={'Authorization':auth}));csrf_ok=False
 except urllib.error.HTTPError as e:csrf_ok=e.code==403
 record('http_csrf_rejected',csrf_ok)
 server.shutdown();server.server_close()
 for cc in actors.values():cc.close()
 # Lock test actors again; passwords never serialized.
 with c.cursor() as cur:
  for name in names:cur.execute(f"ALTER USER '{name}'@'localhost' ACCOUNT LOCK")
 summary=dict(engine=version,executed_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),passed=sum(r['passed'] for r in results),failed=sum(not r['passed'] for r in results),tests=results,query_count=len(queries),scope='fresh isolated local instance; fixtures plus verification-only rows; no historical evidence reused')
 for name,data in [('verification_results.json',summary),('query_results.json',queries)]:
  (EVIDENCE/name).write_text(json.dumps(data,ensure_ascii=False,indent=2,default=str),encoding='utf-8')
 c.close()
 if summary['failed']:raise SystemExit('Verification failures: '+str(summary['failed']))
 print('VERIFIED',summary['passed'],'checks on',version,flush=True)
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--fresh-install',action='store_true');args=parser.parse_args();run(args.fresh_install)
