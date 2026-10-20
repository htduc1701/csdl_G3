"""Local coursework demo. Native MySQL accounts authenticate each request."""
import base64, hashlib, hmac, html, json, os, secrets
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs
import pymysql

KEY=secrets.token_bytes(32)
ACTIONS={
 'post_job':('sp_post_job',['actor','category','title','description','min_budget','max_budget','deadline']),
 'submit_proposal':('sp_submit_proposal',['actor','job','amount','letter','days']),
 'select_proposal':('sp_select_proposal',['actor','proposal']),
 'confirm_proposal':('sp_confirm_proposal',['actor','proposal']),
 'add_milestone':('sp_add_milestone',['actor','contract','title','amount','due']),
 'advance_milestone':('sp_advance_milestone',['actor','milestone','status']),
 'record_payment':('sp_record_payment',['actor','milestone','method','status']),
 'complete_contract':('sp_complete_contract',['actor','contract']),
 'submit_review':('sp_submit_review',['actor','contract','rating','text']),
}
VIEWS=['v_job_proposals','v_contract_overview','v_freelancer_ratings','v_client_spend']
def connect(user,password):
 c=pymysql.connect(host=os.getenv('DB_HOST','127.0.0.1'),port=int(os.getenv('DB_PORT','33370')),
     user=user,password=password,database='mini_upwork',charset='utf8mb4',autocommit=True,
     cursorclass=pymysql.cursors.DictCursor)
 with c.cursor() as cur: cur.execute('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED')
 return c
class Handler(BaseHTTPRequestHandler):
 def log_message(self,fmt,*args): pass
 def send(self,status,body,auth=False):
  self.send_response(status)
  if auth:self.send_header('WWW-Authenticate','Basic realm="G3 local demo"')
  self.send_header('Content-Type','text/html; charset=utf-8')
  self.send_header('Cache-Control','no-store')
  self.send_header('Content-Security-Policy',"default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'")
  self.end_headers();self.wfile.write(body.encode('utf-8'))
 def handle_request(self,post=False):
  auth=self.headers.get('Authorization','')
  try:
   if not auth.startswith('Basic '):raise ValueError()
   user,password=base64.b64decode(auth[6:],validate=True).decode().split(':',1)
   if user=='root':raise ValueError('Use an actor account')
   c=connect(user,password)
  except Exception:
   return self.send(401,'<p>Sign in with a configured native MySQL demo account.</p>',True)
  token=hmac.new(KEY,auth.encode(),hashlib.sha256).hexdigest()
  message=''
  try:
   if post:
    length=int(self.headers.get('Content-Length','0'))
    if length>8192:return self.send(413,'Request too large')
    data=parse_qs(self.rfile.read(length).decode(),keep_blank_values=True)
    if not hmac.compare_digest(data.get('csrf',[''])[0],token):return self.send(403,'Invalid form token')
    action=data.get('action',[''])[0]
    if action not in ACTIONS:return self.send(400,'Unknown action')
    proc,fields=ACTIONS[action]
    args=[data.get(f,[''])[0] or None for f in fields]
    with c.cursor() as cur:
     cur.callproc(proc,args)
     while cur.nextset():pass
    message='Action committed. Refresh the reports below to inspect the result.'
   body='''<!doctype html><html lang="en"><meta charset="utf-8"><title>G3 Mini Upwork</title>
<style>body{font:16px system-ui;max-width:1180px;margin:32px auto;padding:0 20px;color:#18212b}table{border-collapse:collapse;font-size:13px}td,th{border:1px solid #ccd4dc;padding:7px;text-align:left}th{background:#edf2f7}section{overflow:auto;margin:25px 0}form{padding:15px 0;border-bottom:1px solid #ddd}label{display:inline-block;margin:5px}input{padding:7px;width:150px}button{padding:8px 14px}details{margin:10px 0}</style>
<h1>G3 Freelance Marketplace</h1><p>Local coursework demonstration using the database workflow.</p>'''
   body+='<p>Account: '+html.escape(user)+'</p><p>'+html.escape(message)+'</p>'
   body+='<p>Use the forms in workflow order. Contract and milestone IDs appear in the reports; job and proposal IDs are also shown by SQL in the demo guide. An action outside your role is rejected by MySQL.</p>'
   for action,(proc,fields) in ACTIONS.items():
    body+='<details><summary>'+html.escape(action.replace('_',' ').title())+'</summary><form method="post">'
    body+=f'<input type="hidden" name="csrf" value="{token}"><input type="hidden" name="action" value="{action}">'
    for field in fields:
     body+='<label>'+html.escape(field)+'<br><input name="'+field+'" '+('type="date"' if field in ('due','deadline') else '')+'></label>'
    body+='<button type="submit">Execute</button></form></details>'
   for view in VIEWS:
    with c.cursor() as cur:cur.execute('SELECT * FROM '+view+' ORDER BY 1 DESC LIMIT 25');rows=cur.fetchall()
    body+='<section><h2>'+html.escape(view)+'</h2><p>Latest 25 IDs; use SQL for the full dataset.</p>'
    if rows:
     body+='<table><tr>'+''.join('<th>'+html.escape(k)+'</th>' for k in rows[0])+'</tr>'
     for row in rows:body+='<tr>'+''.join('<td>'+html.escape(str(v) if v is not None else 'No rating')+'</td>' for v in row.values())+'</tr>'
     body+='</table>'
    else:body+='<p>No rows.</p>'
    body+='</section>'
   body+='</html>';self.send(200,body)
  except (pymysql.MySQLError,ValueError) as e:
   self.send(400,'<h1>Action rejected</h1><p>'+html.escape(str(e))+'</p><p><a href="/">Return to reports</a></p>')
  finally:c.close()
 def do_GET(self):self.handle_request()
 def do_POST(self):self.handle_request(True)
if __name__=='__main__':
 port=int(os.getenv('APP_PORT','8086'))
 print(f'G3 local demo: http://127.0.0.1:{port}',flush=True)
 ThreadingHTTPServer(('127.0.0.1',port),Handler).serve_forever()
