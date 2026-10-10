# Freelance Marketplace Ecosystem G3

INT1313 database implementation for Report sections4 Database Implementation and5 Verification and Security. This is not semester Phase4 UI/defense integration.

## Run

Requires MySQL8.0.42 (8.0.16 is the minimum CHECK-capable engine; tested exact version8.0.42), Python3.12 and requirements.txt. No MySQL syntax is mixed with another DBMS. Use a fresh disposable database named mini_upwork for tests. Schema installer refuses duplicate tables; it does not silently drop an existing database.

```bash
python -m pip install -r requirements.txt
export MYSQL_ROOT_PASSWORD='set your own local secret'
docker compose up -d
export DB_HOST=127.0.0.1 DB_PORT=3307 DB_USER=root
export DB_PASSWORD="$MYSQL_ROOT_PASSWORD"
python tests/run_tests.py --install
python tests/run_performance.py
```

run_tests.py --install creates the schema and seed, runs rollback tests and committed concurrency fixtures, then explicitly DROPS and recreates only mini_upwork to restore the seed before query assertions. Never point it at project data you wish to keep. It refuses initial duplicate tables rather than dropping them. RBAC tests change selected seed workflow states afterwards and lock demonstration accounts; rebuild the disposable DB for another identical run. run_performance.py creates isolated mini_upwork_perf, refuses to overwrite it and deletes that fixture at completion. Docker volumes preserve data; no automatic volume deletion is provided.

Native RBAC tests require client connections originating on the MySQL host because demonstration accounts are localhost-only. For all checks on a local MySQL installation, set DB_PORT to its port and run `python tests/run_tests.py --install --security` on a fresh mini_upwork schema. Docker host-port connections can appear as bridge addresses, so the default Docker command above runs integrity/query checks without unlocking native role accounts. Do not rerun --install over existing tables. For remote application deployment, replace localhost with a specific approved host and apply TLS before account unlock.

For manual installation, execute SQL files01 through05 in order in the mysql client, then06 for queries and07 using a role-management-capable DBA. Each file uses mini_upwork; seed explicitly uses READ COMMITTED. Trigger budget guards require READ COMMITTED; procedure APIs set it at the next standalone transaction. No INSERT SELECT from locking parent tables; obtain IDs first then use VALUES. Never change isolation mid-transaction or invoke these transaction-owning APIs inside an existing transaction.

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SOURCE sql/01_schema.sql;
SOURCE sql/02_triggers.sql;
SOURCE sql/03_views_indexes.sql;
SOURCE sql/04_procedures.sql;
SOURCE sql/05_seed.sql;
SOURCE sql/06_queries.sql;
SOURCE sql/07_security.sql;
```

Registration inserts users only: a trigger creates the matching subtype atomically. Do not insert a second subtype row; UPDATE its profile instead. Selection and confirmation use distinct authenticated native accounts. Accounts in07 are locked until a DBA sets local secrets and unlocks them. Procedures enforce ownership via connection username; normal roles cannot issue direct table DML. Payment service is trusted to supply confirmed simulated provider outcomes.

## Deliverables

- docs/Freelance_Marketplace_Ecosystem_G3.docx: revised report sections1–5 and mapping appendix.
- docs/audit_report.md:22 findings, decisions and remaining strict normalization exception.
- docs/normalization.md:FDs/candidate keys and3NF/BCNF limits.
- docs/trigger_catalog.md:all trigger SQL, explanations and test references.
- docs/query_report.md and docs/test_report.md:actual results, expected results and execution plans.
- sql/01_schema.sql through07_security.sql:11 tables, triggers,3 views, indexes,7 procedures, seed,12 queries and native RBAC.
- evidence/*.json:machine-readable engine, test, query, security and scale evidence.
- docs/physical_schema.mmd and rendered diagrams:IE Crow Foot relationships and physical mapping.

## Assessment and operational limits

PAYMENT retains explicit payer/payee/amount per BR16 and multiple retry records, so it is2NF with a documented3NF violation (milestone_id determines those non-prime columns). Ten business relations satisfy BCNF under stated FDs when generated helper columns are projected away. Full physical schema BCNF is not claimed. See normalization.md for an11-entity normalized alternative requiring acceptance of derived transfer fields. At-rest encryption, restore-drill targets and a real payment gateway are not deployed. Semester Phase4 integration/defense and peer evaluation remain future work. Measured latency is local warm-cache evidence, not a production SLA.
