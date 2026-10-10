#!/usr/bin/env python3
"""Destructive test installation only when --install is explicitly passed; fresh mini_upwork required."""
import os,sys,json,time,threading,argparse,decimal,datetime,statistics
from pathlib import Path
import pymysql
P=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--install',action='store_true');parser.add_argument('--security',action='store_true');a=parser.parse_args()
base=dict(user=os.getenv('DB_USER','root'),password=os.getenv('DB_PASSWORD',''),autocommit=True)
if os.getenv('DB_SOCKET'):base['unix_socket']=os.environ['DB_SOCKET']
else:base.update(host=os.getenv('DB_HOST','127.0.0.1'),port=int(os.getenv('DB_PORT','3307')))
def connect(db=True,**kwargs):
 cc=pymysql.connect(**(base|({'database':'mini_upwork'} if db else {})|kwargs));cc.cursor().execute('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED');return cc
def script(c,path):
 delimiter=';';buf=''
 for line in path.read_text().splitlines():
  if line.strip().startswith('DELIMITER '):delimiter=line.strip().split()[1];continue
  if line.lstrip().startswith('--'):continue
  buf+=line+'\n'
  if buf.rstrip().endswith(delimiter):
   sql=buf.rstrip()[:-len(delimiter)].strip();buf=''
   if sql:c.cursor().execute(sql)
 if buf.strip():raise RuntimeError('Unterminated SQL in '+str(path))
c=connect(False)
if a.install:
 for name in ['01_schema.sql','02_triggers.sql','03_views_indexes.sql','04_procedures.sql','05_seed.sql']:
  script(c,P/'sql'/name);print('Installed',name,flush=True)
c.close();c=connect();out=[]
def test(id,rule,sqls,code=0,contains=None,check=None):
 if isinstance(sqls,str):sqls=[sqls]
 actual=0;message='accepted';rows=None;c.begin()
 try:
  cur=c.cursor()
  for s in sqls:cur.execute(s)
  if check:
   cur.execute(check);rows=cur.fetchall()
 except pymysql.MySQLError as e:actual=e.args[0];message=str(e)
 finally:c.rollback()
 passed=(actual==code and (contains is None or contains in message))
 out.append(dict(id=id,rule=rule,sql=sqls,expected_error=code,actual_error=actual,message=message,check=check,result=rows,passed=passed))
 print(id,'PASS' if passed else 'FAIL',message,flush=True)
# Mandatory cases and controls. Seed remains unchanged through rollback.
test('TC-01','BR-02',"INSERT INTO freelancers (freelancer_id) VALUES (1)",1644,'BR-02')
test('TC-02','BR-08',"INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (6,6,900,'duplicate',30)",1062)
test('TC-03','BR-14',"INSERT INTO milestones (contract_id,title,amount) VALUES (1,'excess',1)",1644,'BR-14')
test('TC-04','email',"INSERT INTO users (email,full_name,password_hash,user_type) VALUES ('DEMO1@example.test','Duplicate','DEMO','CLIENT')",1062)
test('TC-05','BR-04',"INSERT INTO jobs (client_id,category_id,title,description) VALUES (1,999,'invalid','scope')",1452)
test('TC-06','positive money',"INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (7,4,0,'invalid',10)",3819)
test('TC-07','dates',"INSERT INTO contracts (proposal_id,client_id,freelancer_id,start_date,end_date,total_amount) VALUES (10,3,6,'2026-10-10','2026-10-09',900)",1644,'BR-11')
# To isolate date CHECK, use existing valid contract UPDATE.
test('TC-08','dates',"UPDATE contracts SET end_date = DATE_SUB(start_date,INTERVAL 1 DAY) WHERE contract_id=1",1644,'BR-14')
test('TC-09','BR-11',"INSERT INTO contracts (proposal_id,client_id,freelancer_id,start_date,total_amount) VALUES (10,3,6,CURRENT_DATE,900)",1644,'BR-11')
test('TC-10','BR-10',"UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE proposal_id=11")
# First select job8's proposal then another new contender.
test('TC-11','BR-10',["UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE proposal_id=11","INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (8,4,1000,'other',30)","UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE job_id=8 AND freelancer_id=4"],1062)
test('TC-12','BR-12',"UPDATE contracts SET client_id=2 WHERE contract_id=1",1644,'immutable')
test('TC-13','BR-12',"UPDATE contracts SET freelancer_id=6 WHERE contract_id=1",1644,'immutable')
test('TC-14','BR-11',"UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=11",1644,'BR-11')
test('TC-15','BR-15',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (2,1,4,600,'PAYPAL','PAID')",1644,'BR-15')
test('TC-16','BR-16',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method) VALUES (9,1,4,500,'PAYPAL')",1644,'BR-16')
test('TC-17','BR-16',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method) VALUES (9,3,6,500,'PAYPAL')",1644,'BR-16')
test('TC-18','BR-16',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method) VALUES (9,3,4,499,'PAYPAL')",1644,'BR-16')
test('TC-19','one PAID',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (1,1,4,400,'PAYPAL','PAID')",1062)
test('TC-20','status',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'PAYPAL','REFUNDED')",3819)
test('TC-21','BR-14 update',"UPDATE milestones SET amount=1501 WHERE milestone_id=10",1644,'BR-14')
test('TC-22','BR-14 contract decrease',"UPDATE contracts SET total_amount=999 WHERE contract_id=1",1644,'BR-14')
test('TC-23','BR-02 type switch',"UPDATE users SET user_type='FREELANCER' WHERE user_id=1",1644,'BR-02')
test('TC-24','BR-02 total',"DELETE FROM clients WHERE client_id=3",1644,'BR-02')
test('TC-25','BR-15 skip approval',"UPDATE milestones SET status='APPROVED' WHERE milestone_id=10",1644,'BR-15')
test('TC-26','BR-16 method',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method) VALUES (9,3,4,500,'CASH')",3819)
test('TC-27','payment terminal',"UPDATE payments SET payment_status='FAILED' WHERE payment_id=2",1644,'Terminal')
test('TC-28','BR-15 revoke approval',"UPDATE milestones SET status='COMPLETED' WHERE milestone_id=1",1644,'BR-15')
test('TC-29','payment audit',"DELETE FROM payments WHERE payment_id=1",1644,'evidence')
test('TC-30','job owner',"UPDATE jobs SET client_id=2 WHERE job_id=1",1644,'immutable')
test('TP-01','BR-02 valid registration',"INSERT INTO users (user_id,email,full_name,password_hash,user_type) VALUES (99,'new@example.test','Synthetic new','DEMO','FREELANCER')",check='SELECT COUNT(*) FROM freelancers WHERE freelancer_id=99')
test('TP-02','BR-08 valid proposal',"INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (7,4,500,'valid',20)")
test('TP-03','BR-14 within budget',["UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=10","SELECT contract_id INTO @new_contract FROM contracts WHERE proposal_id=10","INSERT INTO milestones (contract_id,title,amount) VALUES (@new_contract,'within',900)"])
test('TP-04','BR-11 atomic confirmation',"UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=10",check='SELECT COUNT(*) FROM contracts WHERE proposal_id=10')
test('TP-05','BR-15 and BR-16 successful payment',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'PAYPAL','PAID')")
test('TP-06','retry after FAILED',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'BANK_TRANSFER','FAILED')")
test('TP-07','pending becomes PAID',"UPDATE payments SET payment_status='PAID' WHERE payment_id=4")
test('TP-08','work then approval',["UPDATE milestones SET status='APPROVED' WHERE milestone_id=2","INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (2,1,4,600,'CREDIT_CARD','PAID')"])
test('TP-09','completion only after fully paid',["UPDATE milestones SET status='APPROVED' WHERE milestone_id=2","INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (2,1,4,600,'CREDIT_CARD','PAID')","UPDATE contracts SET status='COMPLETED' WHERE contract_id=1"])
test('TC-31','date CHECK isolated',["UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=10", "UPDATE contracts SET end_date=DATE_SUB(start_date,INTERVAL 1 DAY) WHERE proposal_id=10"],3819)
test('TC-32','negative milestone',"UPDATE milestones SET amount=-1 WHERE milestone_id=10",3819)
test('TC-33','contract positive',"UPDATE contracts SET total_amount=0 WHERE contract_id=1",1644,'BR-14')
test('TC-34','deadline',"UPDATE jobs SET deadline='2026-08-31' WHERE job_id=7",3819)
test('TC-35','milestone due',"UPDATE milestones SET due_date='2020-01-01' WHERE milestone_id=10",1644,'date')
test('TC-36','proposal identity',"UPDATE proposals SET freelancer_id=5 WHERE proposal_id=10",1644,'immutable')
test('TC-37','milestone parent',"UPDATE milestones SET contract_id=2 WHERE milestone_id=10",1644,'identity')
test('TC-38','payment update duplicate',"UPDATE payments SET payment_status='PAID' WHERE payment_id=1",1644,'Terminal')
test('TC-39','payment amount immutable',"UPDATE payments SET amount=501 WHERE payment_id=6",1644,'BR-16')
test('TC-40','contract completion',"UPDATE contracts SET status='COMPLETED' WHERE contract_id=1",1644,'Completion')
test('TC-41','subtype identity',"UPDATE freelancers SET freelancer_id=99 WHERE freelancer_id=4",1644,'BR-02')
test('TC-42','subtype retention',"DELETE FROM freelancers WHERE freelancer_id=8",1644,'BR-02')
test('TC-43','milestone audit',"DELETE FROM milestones WHERE milestone_id=10",1644,'retained')
test('TC-44','BR-11 retention',"DELETE FROM contracts WHERE contract_id=1",1644,'BR-11')
test('TC-45','BR-11 initial offer',"INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,status) VALUES (7,4,500,'invalid',20,'CONFIRMED')",1644,'initial')
test('TC-46','BR-12 insert mismatch',"INSERT INTO contracts (proposal_id,client_id,freelancer_id,start_date,total_amount) VALUES (1,2,4,CURRENT_DATE,1000)",1644,'BR-12')
test('TP-10','client profile edit',"UPDATE clients SET company_name='Demo revised' WHERE client_id=1")
test('TP-11','freelancer profile edit',"UPDATE freelancers SET bio='Synthetic profile revision' WHERE freelancer_id=4")
test('TP-12','user edit',"UPDATE users SET full_name='Demo name revision' WHERE user_id=1")
test('TC-48','client subtype identity',"UPDATE clients SET client_id=99 WHERE client_id=1",1644,'BR-02')
test('TC-49','client wrong subtype',"INSERT INTO clients (client_id) VALUES (4)",1644,'BR-02')
test('TP-13','job mutable scope',"UPDATE jobs SET title='Demo revised scope' WHERE job_id=7")
c.cursor().execute('SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ')
test('TC-47','unsupported isolation',"UPDATE milestones SET title='revised' WHERE milestone_id=10",1644,'READ COMMITTED')
c.cursor().execute('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED')
# Exact success checks in addition to error codes.
for r in out:
 if r['check']:r['passed']=r['passed'] and r['result']==((1,),)
# Concurrency: prior consistent read in READ COMMITTED; parent gate precedes aggregate reads.
def race(id,sql1,sql2,cleanup,expected=None):
 c1=connect(autocommit=False);c2=connect(autocommit=False);cur1=c1.cursor();cur2=c2.cursor()
 cur2.execute('SELECT COUNT(*) FROM milestones');cur1.execute(sql1)
 result=[];started=threading.Event()
 def second():
  started.set()
  try:cur2.execute(sql2);c2.commit();result.append(dict(error=0,message='accepted'))
  except pymysql.MySQLError as e:c2.rollback();result.append(dict(error=e.args[0],message=str(e)))
 t=threading.Thread(target=second);t.start();started.wait(2);time.sleep(.2)
 blocked=t.is_alive();c1.commit();t.join(10)
 if t.is_alive():raise RuntimeError('Concurrency worker hung')
 c1.close();c2.close()
 for s in cleanup:c.cursor().execute(s)
 passed=blocked and (result[0]['error'] == expected if expected is not None else result[0]['error'] in (1062,1644,1213))
 out.append(dict(id=id,rule='concurrent gate',sql=[sql1,sql2],expected=('second waits then accepts; total within limit' if expected==0 else 'second waits then rejects; no invariant violation'),actual=result[0],blocked=blocked,passed=passed))
 print(id,'PASS' if passed else 'FAIL',result,flush=True)
# Only insert deletion restrictions prevent cleanup; use rollback race variant on scratch new contract;
# create a dedicated proposal/contract then keep evidence in temporary transaction? use decrease race on existing pending milestone.
race('CC-01',"UPDATE milestones SET amount=1400 WHERE milestone_id=10", "UPDATE milestones SET amount=1601 WHERE milestone_id=10", ["UPDATE milestones SET amount=1500 WHERE milestone_id=10"])
# Distinct insert race uses an isolated contract; started milestone terms stay immutable.
# Create isolated work via selected proposal10 for insert race and restore confirmed state via separate test database later.
cur=c.cursor();cur.execute("UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=10");cur.execute('SELECT contract_id FROM contracts WHERE proposal_id=10');cid=cur.fetchone()[0]
race('CC-02',f"INSERT INTO milestones (contract_id,title,amount) VALUES ({cid},'race first',600)",f"INSERT INTO milestones (contract_id,title,amount) VALUES ({cid},'race second',600)",[])
# Selection uniqueness race on open job8, with two distinct freelancers.
cur.execute("INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (8,4,1000,'race selection',30)")
race('CC-04',"UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE proposal_id=11", "UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE job_id=8 AND freelancer_id=4",[])
# Payment paid uniqueness race on already approved milestone9; preserve seed after by use fresh install for query results.
race('CC-03',"INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'PAYPAL','PAID')","INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'PAYPAL','PAID')",[])
cur.execute("UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=11")
cur.execute('SELECT contract_id FROM contracts WHERE proposal_id=11');cid2=cur.fetchone()[0]
race('CC-05',f"INSERT INTO milestones (contract_id,title,amount) VALUES ({cid2},'exact first',600)",f"INSERT INTO milestones (contract_id,title,amount) VALUES ({cid2},'exact second',600)",[],expected=0)
# Verify end-state invariants, not simply catching any exception.
checks={
 'milestone_limit':"SELECT COUNT(*) FROM (SELECT c.contract_id FROM contracts c JOIN milestones m ON m.contract_id=c.contract_id GROUP BY c.contract_id,c.total_amount HAVING SUM(m.amount)>c.total_amount) t",
 'one_paid':"SELECT COUNT(*) FROM (SELECT milestone_id FROM payments WHERE payment_status='PAID' GROUP BY milestone_id HAVING COUNT(*)>1) t",
 'one_selected':"SELECT COUNT(*) FROM (SELECT job_id FROM proposals WHERE status IN ('CLIENT_ACCEPTED','CONFIRMED') GROUP BY job_id HAVING COUNT(*)>1) t",
 'total_subtype':"SELECT COUNT(*) FROM users u LEFT JOIN clients c ON c.client_id=u.user_id LEFT JOIN freelancers f ON f.freelancer_id=u.user_id WHERE (c.client_id IS NOT NULL)+(f.freelancer_id IS NOT NULL)<>1",
 'confirmed_contract':"SELECT COUNT(*) FROM proposals p LEFT JOIN contracts c ON c.proposal_id=p.proposal_id WHERE p.status='CONFIRMED' AND c.contract_id IS NULL"
}
for k,s in checks.items():
 cur.execute(s);n=cur.fetchone()[0];out.append(dict(id='INV-'+k,sql=[s],expected=0,actual=n,passed=n==0))
# Save and restore seed by dropping ONLY explicit test schema when --install selected.
P.joinpath('evidence/test_results.json').write_text(json.dumps(out,indent=2,default=str))
if a.install:
 c.close();c=connect(False);c.cursor().execute('DROP DATABASE mini_upwork')
 for name in ['01_schema.sql','02_triggers.sql','03_views_indexes.sql','04_procedures.sql','05_seed.sql']:script(c,P/'sql'/name)
 c.close();c=connect()
queries=json.loads(P.joinpath('docs/query_catalog.json').read_text());results=[]
for q in queries:
 cur=c.cursor();times=[]
 for i in range(11):
  t=time.perf_counter();cur.execute(q['sql']);rows=cur.fetchall();times.append((time.perf_counter()-t)*1000)
 cur.execute('EXPLAIN FORMAT=JSON '+q['sql']);plan=json.loads(cur.fetchone()[0])
 cur.execute('EXPLAIN ANALYZE '+q['sql']);analyze=cur.fetchone()[0]
 results.append(q|dict(actual=rows,median_ms=statistics.median(times[1:]),explain=plan,explain_analyze=analyze))
# Explicit expected values below are independent of query SQL.
validators={
 'Q-01': lambda r:[int(x[5]) for x in r]==[2,2,2,1,2,1,0,1],
 'Q-02': lambda r:[list(x) for x in r]==[[4,3],[6,3],[7,2],[8,2]],
 'Q-03': lambda r:[x[0] for x in r]==[7],
 'Q-04': lambda r:[(x[0],str(x[1]),x[2]) for x in r]==[(4,'3000.00',1),(6,'1500.00',2),(5,'800.00',3),(7,'600.00',4)],
 'Q-05': lambda r:[str(x[2]) for x in r]==['700.00','200.00','0.00'],
 'Q-06': lambda r:[str(x[3]) for x in r]==['600.00','500.00','1500.00','400.00','2000.00'],
 'Q-07': lambda r:[x[0] for x in r]==[2,5,9],
 'Q-08': lambda r:[x[0] for x in r]==[3,5,8],
 'Q-09': lambda r:[(x[0],x[2]) for x in r]==[(4,3),(6,3)],
 'Q-10': lambda r:[str(x[7]) for x in r]==['400.00','300.00','0.00','200.00','0.00'] and all(x[5]==2 for x in r),
 'Q-11': lambda r:[list(x) for x in r]==[[1,3],[2,3]],
 'Q-12': lambda r:[list(x) for x in r]==[[1,1],[2,1],[3,1],[4,1],[5,1]]}
for r in results:
 r['passed']=validators[r['id']](r['actual'])
 out.append(dict(id=r['id'],passed=r['passed']))
P.joinpath('evidence/query_results.json').write_text(json.dumps(results,indent=2,default=str))
cur.execute('SELECT VERSION(), @@transaction_isolation, @@sql_mode');environment=cur.fetchone()
cur.execute('SHOW INDEX FROM proposals');idx=cur.fetchall()
P.joinpath('evidence/environment.json').write_text(json.dumps(dict(environment=environment,indexes=idx),indent=2,default=str))
# Optional RBAC runs provisioned accounts on a disposable local server. No fixed secret is stored.
if a.security:
 script(c,P/'sql/07_security.sql');sec=[]
 accounts=['client_1','client_2','freelancer_4','payment_service','report_reader']
 import secrets
 password=secrets.token_urlsafe(32)
 for acc in accounts:cur.execute(f"ALTER USER '{acc}'@'localhost' IDENTIFIED BY %s ACCOUNT UNLOCK",(password,))
 def action(id,acc,sql,code=0,contains=None):
  cc=connect(user=acc,password=password)
  try:cc.cursor().execute(sql);err=0;msg='accepted'
  except pymysql.MySQLError as e:err=e.args[0];msg=str(e)
  finally:cc.close()
  sec.append(dict(id=id,account=acc,sql=sql,expected_error=code,actual_error=err,message=msg,expected_message=contains,passed=err==code and (contains is None or contains in msg)))
 action('SEC-01','client_1',"UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=11",1142)
 action('SEC-02','report_reader','SELECT password_hash FROM users',1142)
 action('SEC-03','report_reader','SELECT * FROM v_contract_overview')
 action('SEC-04','report_reader','SELECT * FROM skills',1142)
 action('SEC-05','client_1','CALL sp_select_proposal(2,11)',1644)
 action('SEC-06','client_1','CALL sp_select_proposal(1,11)',1644)
 action('SEC-13','client_1','CALL sp_select_proposal(NULL,11)',1644,'Actor')
 action('SEC-07','client_2','CALL sp_select_proposal(2,11)')
 action('SEC-08','freelancer_4','CALL sp_confirm_proposal(4,11)',1644)
 action('SEC-14','client_1',"CALL sp_advance_milestone(NULL,2,'APPROVED')",1644,'Only owning client')
 action('SEC-15','client_1',"CALL sp_add_milestone(NULL,1,'bad',1,NULL)",1644,'Only owning client')
 action('SEC-09','client_1',"CALL sp_advance_milestone(1,2,'APPROVED')")
 action('SEC-10','freelancer_4',"CALL sp_advance_milestone(4,2,'APPROVED')",1644)
 action('SEC-11','client_1',"CALL sp_record_payment(1,2,'PAYPAL','PAID')",1370)
 action('SEC-12','payment_service',"CALL sp_record_payment(1,2,'PAYPAL','PAID')")
 action('SEC-16','client_1',"CALL sp_post_job(1,1,'RBAC demo job','Synthetic',100,500,NULL)")
 cur.execute("SELECT job_id FROM jobs WHERE title='RBAC demo job'");jid=cur.fetchone()[0]
 action('SEC-17','freelancer_4',f"CALL sp_submit_proposal(4,{jid},500,'Synthetic',30)")
 cur.execute('SELECT proposal_id FROM proposals WHERE job_id=%s',(jid,));pid=cur.fetchone()[0]
 action('SEC-18','client_1',f"CALL sp_select_proposal(1,{pid})")
 action('SEC-19','freelancer_4',f"CALL sp_confirm_proposal(4,{pid})")
 cur.execute('SELECT contract_id FROM contracts WHERE proposal_id=%s',(pid,));cid=cur.fetchone()[0]
 action('SEC-20','client_1',f"CALL sp_add_milestone(1,{cid},'Demo delivery',500,NULL)")
 for acc in accounts:cur.execute(f"ALTER USER '{acc}'@'localhost' ACCOUNT LOCK")
 P.joinpath('evidence/security_results.json').write_text(json.dumps(sec,indent=2))
 out+=sec
print('TOTAL',sum(r['passed'] for r in out),'/',len(out))
sys.exit(0 if all(r['passed'] for r in out) else 1)
