# Mini-Upwork G3 - MySQL Database and Flask Web Application

The **Freelance Marketplace Ecosystem** project includes an installable database and a Flask web application demonstrating the marketplace workflow.

See the [Windows setup and demonstration guide](tutorial.md) or the [sample dataset guide](Freelance_Marketplace_Ecosystem_SQL/README.md).

## Project and Repository Information

| Field | Details |
|---|---|
| Institution | Posts and Telecommunications Institute of Technology, Ho Chi Minh City Campus (PTITHCM) |
| Class | D25CQAT02-N |
| Course | INT1313 - Databases |
| Semester | Semester 1, academic year 2026-2027 |
| Project | Project 3 - Mini Upwork: Freelance Marketplace Ecosystem |
| Team | G3 |
| Repository | [htduc1701/csdl_G3](https://github.com/htduc1701/csdl_G3) |
| Default branch | `main` |
| Instructor contact | `lehathanh@ptithcm.edu.vn` |

## Team Members

All members are PTITHCM students. Their full names, student IDs, institutional email addresses, and GitHub accounts are listed below.

| Student ID | Full name | PTITHCM student email | GitHub account |
|---|---|---|---|
| N25DCAT073 | Huỳnh Thiện Đức | `n25dcat073@student.ptithcm.edu.vn` | [htduc1701](https://github.com/htduc1701) |
| N25DCAT076 | Phạm Việt Hoàng | `n25dcat076@student.ptithcm.edu.vn` | [shinmagicc](https://github.com/shinmagicc) |
| N25DCAT079 | Đặng Quang Huy | `n25dcat079@student.ptithcm.edu.vn` | [Kurookani](https://github.com/Kurookani) |

## 1. Current Environment and Design

- DBMS: locally installed MySQL Community Server, typically on port `3306`.
- The [test log dated November 14, 2026](audit_test_results/FRESH_TEST_RUN_2026-11-14.md) records **84/84 assertions passed** on a server reporting version `26.7.0`, using the base dataset in a disposable schema. This result does not certify compatibility with MySQL `8.0.42`.
- The optional Docker Compose configuration uses MySQL `8.0.42`, mapping host port `3307` to container port `3306`.
- Storage engine: InnoDB.
- Transaction isolation for workflow write operations: `READ COMMITTED`.
- Business tables: **11**.
- Web backend: Flask.
- Python: version `3.13` was used for the local demo; dependencies are listed in `requirements.txt`.
- SQL installation tool: MySQL Workbench.
- MySQL drivers: `mysql-connector-python` for Flask and `PyMySQL` for test utilities.

The normalized `payments` table stores only payment-attempt facts:

```text
payments(
    payment_id PK,
    milestone_id FK,
    payment_status,
    payment_method,
    paid_milestone_id UQ [generated column]
)
```

`PK` denotes a primary key, `FK` a foreign key, and `UQ` a unique constraint. The payer, payee, and amount are derived through `payments -> milestones -> contracts`.

## 2. Important Files and Directories

Source code and SQL scripts are in [Freelance_Marketplace_Ecosystem_SQL](Freelance_Marketplace_Ecosystem_SQL). Paths in the following table are relative to that directory.

| Path | Description |
|---|---|
| `app/` | Flask templates and database connection helpers |
| `main.py` | Flask application entry point |
| `sql/01_schema.sql` | Tables, keys, and `CHECK` constraints |
| `sql/02_triggers.sql` | Workflow and integrity triggers |
| `sql/03_views_indexes.sql` | Reporting views and indexes |
| `sql/04_procedures.sql` | Stored procedures used by the application |
| `sql/05_seed.sql` | Base fictional sample dataset |
| `sql/06_queries.sql` | 12 advanced queries |
| `sql/07_security.sql` | Roles and sample MySQL accounts |
| `sql/08_seed_1000_jobs.sql` | Dataset extension adding 1,000 jobs |
| `sql/09_verify_counts.sql` | Exact row-count verification |
| `INSTALL_DATABASE.sql` | Full installation bundle assembled from the modular SQL scripts |
| `SAMPLE_DATA.sql` | Combined base and expanded sample dataset |
| `SETUP_LOCAL_DEMO.sql` | Sets sample passwords and unlocks the three demo accounts |
| `tests/` | Regression, performance, and large-dataset tests |
| `evidence/` | Archived or generated test evidence |
| `docs/` | Design and verification documentation |
| `requirements.txt` | Python dependencies for the application and tests |
| `compose.yaml` | Optional MySQL configuration using Docker Compose |

## 3. Database Installation

### Option A - Single-File Installation in MySQL Workbench

Use this option for a **fresh** database without the project's business tables.

1. Open MySQL Workbench and connect with an administrative account.
2. Open [INSTALL_DATABASE.sql](Freelance_Marketplace_Ecosystem_SQL/INSTALL_DATABASE.sql).
3. Run the entire script; stop and investigate if any statement reports an error.
4. Refresh **Schemas** to see the `mini_upwork` schema.
5. The final section executes the contents of `sql/09_verify_counts.sql`. For the original expanded dataset, the expected total is **7,223 rows**, including **1,008 jobs** in the `jobs` table.

`INSTALL_DATABASE.sql` is assembled from the modular scripts using the normalized design. The `payments` table no longer contains the legacy `payer_id`, `payee_id`, or `amount` columns.

### Option B - Modular Installation

On a fresh database, run the files in `sql/` in this order:

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

Then run `06_queries.sql` to demonstrate the advanced queries.

**Do not reload** `05_seed.sql`, `08_seed_1000_jobs.sql`, `SAMPLE_DATA.sql`, or `INSTALL_DATABASE.sql` into a demo database that already contains the complete dataset.

## 4. Sample-Data-Only Bundle

`SAMPLE_DATA.sql` combines the contents of:

```text
sql/05_seed.sql
sql/08_seed_1000_jobs.sql
```

Use it only after installing `01_schema.sql` through `04_procedures.sql` while the business tables are still empty. If `INSTALL_DATABASE.sql` has already been run, do not run `SAMPLE_DATA.sql` as well.

## 5. Python Environment Setup

These steps deploy the application locally on Windows with MySQL and Flask.

If you have not downloaded the repository, open PowerShell and run:

```powershell
git clone https://github.com/htduc1701/csdl_G3.git
Set-Location .\csdl_G3
```

From the repository root, prepare the Python environment:

```powershell
Set-Location .\Freelance_Marketplace_Ecosystem_SQL
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

If you are already in `Freelance_Marketplace_Ecosystem_SQL`, skip `Set-Location`. Run the remaining commands from that directory too. Calling Python directly from `.venv` uses the correct environment without activation or changes to the PowerShell execution policy.

Dependencies in `requirements.txt`:

```text
Flask
mysql-connector-python
PyMySQL[rsa]==1.1.2
```

## 6. Running the Flask Application

Start the MySQL service. After installing the database, run [SETUP_LOCAL_DEMO.sql](Freelance_Marketplace_Ecosystem_SQL/SETUP_LOCAL_DEMO.sql) as an administrator to set sample passwords and unlock the demo accounts.

Set the connection details in the PowerShell session used to run Flask:

```powershell
$env:DB_HOST = 'localhost'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$env:DB_PASSWORD = Read-Host 'Enter the MySQL root password' -MaskInput
.\.venv\Scripts\python.exe main.py
```

If PowerShell does not support `-MaskInput`, replace the password input line with the following before running `main.py`:

```powershell
$mysqlPassword = Read-Host 'Enter the MySQL root password' -AsSecureString
$env:DB_PASSWORD = [System.Net.NetworkCredential]::new('', $mysqlPassword).Password
```

The `root` example matches the current demo configuration: the application uses `DB_USER`/`DB_PASSWORD` for read connections, while Client, Freelancer, and payment-service writes use separate accounts defined in `app/db.py`.

Open [http://127.0.0.1:5000](http://127.0.0.1:5000). Keep PowerShell open during the demonstration; press `Ctrl+C` to stop the application.

Main demonstration workflow:

1. The Client posts a Job.
2. The Freelancer submits a Proposal.
3. The Client selects the Proposal.
4. The Freelancer confirms; the system creates a Contract.
5. The Client creates a Milestone.
6. The Freelancer starts and completes the work.
7. The Client approves the Milestone.
8. A simulated Payment is recorded.
9. The results appear on the reports page.

The main demo uses Client ID **`1`** and Freelancer ID **`4`**. This is an educational prototype; payment functionality records status only and does not charge real money.

## 7. Verifying the Expanded Dataset

Set the connection variables for the MySQL instance containing the expanded dataset. A local installation typically uses port `3306`; the project's Compose configuration uses port `3307`.

```powershell
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$env:DB_PASSWORD = Read-Host 'Enter the MySQL root password' -MaskInput
.\.venv\Scripts\python.exe tests\verify_large_dataset.py
```

If PowerShell does not support `-MaskInput`, use the `-AsSecureString` alternative in Section 6.

Expected row counts for the original dataset:

| Table | Rows |
|---|---:|
| `users` | 248 |
| `clients` | 43 |
| `freelancers` | 205 |
| `skills` | 26 |
| `freelancer_skills` | 610 |
| `job_categories` | 11 |
| `jobs` | 1,008 |
| `proposals` | 1,811 |
| `contracts` | 605 |
| `milestones` | 1,810 |
| `payments` | 846 |
| **Total** | **7,223** |

These counts apply **before adding demo data**. Posting jobs, submitting proposals, or recording payments may increase the actual counts and cause the fixed-count verifier to report a mismatch.

The verifier uses the normalized `payments` table and checks payment and work states. It only reads the database, but writes its results to `evidence/large_dataset_results.json`.

## 8. Running the Regression Suite

**Warning:** `tests/run_tests.py --install` includes a step that drops and rebuilds the `mini_upwork` schema. Run it only on a separate MySQL instance dedicated to testing, with no data that must be preserved. Running without `--install` can still change data during test cases; do not use it on a demo database that must remain intact.

The example below assumes a separate test instance listening on port `3307`; replace this with its actual port. A different port alone does not guarantee isolation.

```powershell
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '3307'
$env:DB_USER = 'root'
$env:DB_PASSWORD = Read-Host 'Enter the test MySQL password' -MaskInput
.\.venv\Scripts\python.exe tests\run_tests.py --install
```

If PowerShell does not support `-MaskInput`, use the `-AsSecureString` alternative in Section 6 with the test instance's password.

To include role-based access control (RBAC) checks using MySQL accounts:

```powershell
.\.venv\Scripts\python.exe tests\run_tests.py --install --security
```

Evidence files written during the run:

| File | Description |
|---|---|
| `evidence/test_results.json` | Integrity and workflow test results |
| `evidence/query_results.json` | Query test results |
| `evidence/security_results.json` | Authorization results when `--security` is used |
| `evidence/environment.json` | Test environment details |

The regression suite uses the base sample dataset. The recorded 84/84 result in Section 1 excludes RBAC, large-dataset, and performance tests.

## 9. Performance Testing

After setting the connection variables for the test instance, run the optional PyMySQL-based script:

```powershell
.\.venv\Scripts\python.exe tests\run_performance.py
```

Historical performance figures in the report are archived measurements. Rerun the script when fresh benchmark evidence is required.

## 10. Access Control and Functional Scope

- Client, Freelancer, and payment-service writes use stored procedures; triggers and constraints enforce the business workflow.
- The corresponding application roles are not granted direct table modification privileges. The `payment_service` account calls `sp_record_payment` to record payments.
- The application demonstrates job posting, proposal submission and confirmation, contract creation, milestone management, and reporting.
- Payments are simulated through database records and statuses; real payment gateways, escrow, and refunds are not integrated.
- Accounts and passwords in `SETUP_LOCAL_DEMO.sql` are for local testing. A complete user authentication mechanism has not been implemented.
