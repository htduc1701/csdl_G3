# Mini-Upwork G3 - MySQL + Flask

This folder contains the executable database and the Phase 4 web prototype for the **Freelance Marketplace Ecosystem** project.

## Team G3

## Team G3

| MSSV | Họ và tên | Tài khoản GitHub |
|---|---|---|
| N25DCAT073 | Huynh Thien Duc | [htduc1701](https://github.com/htduc1701) |
| N25DCAT076 | Pham Viet Hoang | [shinmagicc](https://github.com/shinmagicc) |
| N25DCAT079 | Dang Quang Huy | [Kurookani](https://github.com/Kurookani) |


## 1. Current baseline

- DBMS: MySQL 8.0 (validated design target: MySQL 8.0.42 or newer compatible 8.0 release)
- Storage engine: InnoDB
- Transaction isolation for supported workflow writes: READ COMMITTED
- Business tables: 11
- Web backend: Flask
- Python DB drivers: `mysql-connector-python` for the Flask app and `PyMySQL` for test utilities

The normalized PAYMENT table stores only payment-attempt facts:

```text
payments(
    payment_id PK,
    milestone_id FK,
    payment_status,
    payment_method,
    paid_milestone_id UQ [generated]
)
```

Payer, payee, and amount are derived through `payments -> milestones -> contracts`.

## 2. Important files

```text
app/                         Flask templates and database helpers
main.py                      Flask application entry point
sql/01_schema.sql            Tables, keys, CHECK constraints
sql/02_triggers.sql          Workflow/integrity triggers
sql/03_views_indexes.sql     Reporting views and indexes
sql/04_procedures.sql        Stored procedure API
sql/05_seed.sql              Base fictional seed
sql/06_queries.sql           12 advanced queries
sql/07_security.sql          Roles and native demo accounts
sql/08_seed_1000_jobs.sql    Large-data extension
sql/09_verify_counts.sql     Row-count verification
INSTALL_DATABASE.sql         Synchronized one-file full installation bundle
SAMPLE_DATA.sql              Synchronized base + large sample-data bundle
tests/                       Automated regression/performance/large-data checks
evidence/                    Archived/generated test evidence
docs/                        Design and verification documentation
requirements.txt             Python runtime/test dependencies
```

## 3. Install the database

### Option A - one-file installation in MySQL Workbench

Use this for a **fresh** local database.

1. Open MySQL Workbench with an administrative account.
2. Open `INSTALL_DATABASE.sql`.
3. Run the whole script and stop if any statement reports an error.
4. Refresh the `mini_upwork` schema.
5. The final section runs `sql/09_verify_counts.sql`; for the supplied expanded fixture the expected total is **7,223 rows**, including **1,008 jobs**.

`INSTALL_DATABASE.sql` is generated from the current normalized modular files. It no longer contains the legacy PAYMENT fields `payer_id`, `payee_id`, or `amount`.

### Option B - modular installation

Run in this order on a new database:

```text
01_schema.sql
02_triggers.sql
03_views_indexes.sql
04_procedures.sql
05_seed.sql
08_seed_1000_jobs.sql
07_security.sql
09_verify_counts.sql
```

Then run `06_queries.sql` when you want to demonstrate the advanced queries.

Do **not** reload `05_seed.sql`, `08_seed_1000_jobs.sql`, `SAMPLE_DATA.sql`, or `INSTALL_DATABASE.sql` into an already populated demo database.

## 4. Sample-data-only bundle

`SAMPLE_DATA.sql` contains the synchronized contents of:

```text
sql/05_seed.sql
sql/08_seed_1000_jobs.sql
```

Use it only after `01_schema.sql` through `04_procedures.sql` have already been installed on an empty business schema.

## 5. Python environment

From this directory:

```powershell
python -m venv .venv
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

`requirements.txt` now includes all dependencies needed by both the Flask app and test scripts:

```text
Flask
mysql-connector-python
PyMySQL[rsa]
```

## 6. Run the Flask Phase 4 demo

Ensure MySQL is running and the local demo accounts used by `app/db.py` are configured for your machine. Then:

```powershell
.\.venv\Scripts\Activate.ps1
python main.py
```

Open:

```text
http://127.0.0.1:5000
```

Main demonstration flow:

```text
Client posts Job
-> Freelancer submits Proposal
-> Client selects Proposal
-> Freelancer confirms
-> Contract is created
-> Client creates Milestone
-> Freelancer starts/completes work
-> Client approves
-> Payment is recorded
-> Reports reflect the result
```

The classroom demo currently uses Client ID `1` and Freelancer ID `4` for the principal workflow. This is not a production authentication system.

## 7. Verify the expanded fixture

Set the connection variables for the MySQL instance that contains the expanded fixture. Example for a normal local MySQL installation on port 3306:

```powershell
$env:DB_HOST="127.0.0.1"
$env:DB_PORT="3306"
$env:DB_USER="root"
$env:DB_PASSWORD="YOUR_LOCAL_ROOT_PASSWORD"
python tests\verify_large_dataset.py
```

Expected high-level result:

```text
users              248
clients             43
freelancers         205
skills              26
freelancer_skills   610
job_categories      11
jobs                1008
proposals           1811
contracts           605
milestones          1810
payments            846
TOTAL               7223
```

The verifier uses the normalized PAYMENT relation and checks payment/work state instead of removed payer/payee/amount columns.

## 8. Run the normalized regression suite

**Warning:** `tests/run_tests.py --install` is destructive for the `mini_upwork` schema. Use a disposable/local test instance, not the database containing work you want to keep.

Example using a dedicated local MySQL instance:

```powershell
$env:DB_HOST="127.0.0.1"
$env:DB_PORT="3306"
$env:DB_USER="root"
$env:DB_PASSWORD="YOUR_LOCAL_ROOT_PASSWORD"
python tests\run_tests.py --install
```

To include the native-account RBAC checks:

```powershell
python tests\run_tests.py --install --security
```

The test runner has been synchronized with the normalized PAYMENT columns. A successful run rewrites evidence such as:

```text
evidence/test_results.json
evidence/query_results.json
evidence/security_results.json   (when --security is used)
evidence/environment.json
```

Do not change report rows from **Not rerun** to **PASS** until the corresponding current-version run completes successfully and its evidence is saved.

## 9. Performance test

The optional performance script uses PyMySQL and a local MySQL connection:

```powershell
python tests\run_performance.py
```

Historical benchmark numbers in the report are archived measurements; run again if fresh benchmark evidence is required.

## 10. Security and scope notes

- Application write operations use stored procedures and database workflow rules.
- The trusted `payment_service` account is the only application role intended to call `sp_record_payment`.
- Direct table DML is not granted to the normal client/freelancer/payment application roles.
- The Phase 4 Flask application is a classroom prototype, not a production authentication/payment system.
- Escrow, refunds, real payment-gateway charging, provider idempotency, password recovery, messaging, and matching algorithms are outside scope.
- Do not commit real production passwords or payment credentials.

## 11. Recommended submission contents

Keep:

```text
app/
docs/
evidence/
sql/
tests/
main.py
requirements.txt
README.md
compose.yaml
INSTALL_DATABASE.sql
SAMPLE_DATA.sql
```

Do not include `.venv/`, `__pycache__/`, `*.pyc`, or `.git/` in the submission ZIP.
