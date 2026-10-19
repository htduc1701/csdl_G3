"""Read-only verification of the expanded fixture. Requires 01-05 and 08 installed."""
import os, json
from pathlib import Path
import pymysql

P = Path(__file__).resolve().parents[1]
c = pymysql.connect(host=os.getenv('DB_HOST', '127.0.0.1'),
    port=int(os.getenv('DB_PORT', '3307')), user=os.getenv('DB_USER', 'root'),
    password=os.getenv('DB_PASSWORD', ''), database='mini_upwork', autocommit=True)
cur = c.cursor()
expected = dict(users=248, clients=43, freelancers=205, skills=26,
    freelancer_skills=610, job_categories=11, jobs=1008, proposals=1811,
    contracts=605, milestones=1810, payments=846)
counts = {}
for table, number in expected.items():
    cur.execute(f'SELECT COUNT(*) FROM {table}')
    counts[table] = cur.fetchone()[0]
    assert counts[table] == number, (table, counts[table], number)
assert sum(counts.values()) == 7223
cur.execute('SELECT COUNT(DISTINCT full_name) FROM users')
assert cur.fetchone()[0] == 248
cur.execute('SELECT COUNT(DISTINCT title) FROM jobs')
assert cur.fetchone()[0] == 1008
cur.execute("SELECT COUNT(*) FROM users WHERE full_name LIKE 'Demo %' OR full_name LIKE 'Synthetic %'")
assert cur.fetchone()[0] == 0
cur.execute("SELECT COUNT(*) FROM jobs WHERE title LIKE 'Demo %' OR description LIKE 'Synthetic %'")
assert cur.fetchone()[0] == 0
cur.execute('''SELECT COUNT(*) FROM proposals p JOIN jobs j ON j.job_id=p.job_id
    WHERE p.job_id>=22001 AND MOD(p.freelancer_id-21001,8)<>j.category_id-20001''')
assert cur.fetchone()[0] == 0
checks = {
    'subtype_violation': """SELECT COUNT(*) FROM users u LEFT JOIN clients c ON c.client_id=u.user_id
        LEFT JOIN freelancers f ON f.freelancer_id=u.user_id
        WHERE (c.client_id IS NOT NULL)+(f.freelancer_id IS NOT NULL)<>1
           OR (u.user_type='CLIENT' AND c.client_id IS NULL)
           OR (u.user_type='FREELANCER' AND f.freelancer_id IS NULL)""",
    'duplicate_proposal_pair': 'SELECT COUNT(*) FROM (SELECT job_id,freelancer_id FROM proposals GROUP BY job_id,freelancer_id HAVING COUNT(*)>1) x',
    'multiple_selected': "SELECT COUNT(*) FROM (SELECT job_id FROM proposals WHERE status IN ('CLIENT_ACCEPTED','CONFIRMED') GROUP BY job_id HAVING COUNT(*)>1) x",
    'missing_confirmed_contract': "SELECT COUNT(*) FROM proposals p LEFT JOIN contracts c ON c.proposal_id=p.proposal_id WHERE p.status='CONFIRMED' AND c.contract_id IS NULL",
    'bad_contract_parties': 'SELECT COUNT(*) FROM contracts c JOIN proposals p ON p.proposal_id=c.proposal_id JOIN jobs j ON j.job_id=p.job_id WHERE c.client_id<>j.client_id OR c.freelancer_id<>p.freelancer_id OR c.total_amount<>p.proposed_amount',
    'milestone_overflow': 'SELECT COUNT(*) FROM (SELECT c.contract_id FROM contracts c JOIN milestones m ON m.contract_id=c.contract_id GROUP BY c.contract_id,c.total_amount HAVING SUM(m.amount)>c.total_amount) x',
    'bad_payment': "SELECT COUNT(*) FROM payments p JOIN milestones m ON m.milestone_id=p.milestone_id JOIN contracts c ON c.contract_id=m.contract_id WHERE m.status<>'APPROVED' OR p.payer_id<>c.client_id OR p.payee_id<>c.freelancer_id OR p.amount<>m.amount",
    'multiple_paid': "SELECT COUNT(*) FROM (SELECT milestone_id FROM payments WHERE payment_status='PAID' GROUP BY milestone_id HAVING COUNT(*)>1) x",
    'milestone_dates': 'SELECT COUNT(*) FROM milestones m JOIN contracts c ON c.contract_id=m.contract_id WHERE m.due_date<c.start_date OR m.due_date>c.end_date',
}
actual = {}
for name, sql in checks.items():
    cur.execute(sql); actual[name] = cur.fetchone()[0]
    assert actual[name] == 0, (name, actual[name])
states = {}
for table, column in [('jobs','status'), ('proposals','status'), ('contracts','status'),
                      ('milestones','status'), ('payments','payment_status')]:
    cur.execute(f'SELECT {column}, COUNT(*) FROM {table} GROUP BY {column} ORDER BY {column}')
    states[table] = dict(cur.fetchall())
# Execute the existing advanced queries against the enlarged data, rather than reuse small-seed expectations.
queries = []
source = '\n'.join(line for line in (P/'sql/06_queries.sql').read_text().splitlines()
    if not line.lstrip().startswith('--'))
for statement in source.split(';'):
    statement = statement.strip()
    if not statement or statement.upper().startswith('USE '): continue
    cur.execute(statement)
    rows = cur.fetchall()
    queries.append(dict(sql=statement, columns=[d[0] for d in cur.description],
        row_count=len(rows), first_10_rows=rows[:10]))
assert len(queries) == 12
cur.execute('SELECT VERSION(), @@transaction_isolation')
environment = cur.fetchone()
result = dict(environment=environment, counts=counts, total_rows=sum(counts.values()),
    realistic_data_checks=dict(unique_people=248, unique_job_titles=1008,
        placeholder_names=0, placeholder_jobs=0, category_assignment_mismatches=0),
    invariant_violations=actual, status_distribution=states, advanced_queries=queries,
    advanced_queries_executed=12, passed=True)
(P/'evidence/large_dataset_results.json').write_text(json.dumps(result, indent=2, default=str))
c.close()
print(json.dumps(dict(counts=counts, total_rows=sum(counts.values()),
    zero_violation_checks=len(checks), advanced_queries_executed=len(queries), passed=True), indent=2))
