# Mini-Upwork G3 — Freelance Marketplace Ecosystem

A MySQL database and Flask web application demonstrating job posting, proposals, contract creation, milestones, simulated payments, and reporting.

## 1. Project information

| Field | Details |
|---|---|
| Institution | Posts and Telecommunications Institute of Technology, Ho Chi Minh City Campus (PTITHCM) |
| Class | D25CQAT02-N |
| Course | INT1313 — Databases |
| Semester | Semester 1, academic year 2026–2027 |
| Project | Project 3 — Mini Upwork: Freelance Marketplace Ecosystem |
| Team | G3 |
| Repository | [htduc1701/csdl_G3](https://github.com/htduc1701/csdl_G3) |
| Default branch | `main` |
| Instructor contact | `lehathanh@ptithcm.edu.vn` |

### Team members

| Student ID | Full name | PTITHCM email | GitHub account |
|---|---|---|---|
| Instructor | Lê Hà Thanh | `lehathanh@ptithcm.edu.vn` | [lehathanh@ptithcm.edu.vn] |
| N25DCAT073 | Huỳnh Thiện Đức | `n25dcat073@student.ptithcm.edu.vn` | [htduc1701](https://github.com/htduc1701) |
| N25DCAT076 | Phạm Việt Hoàng | `n25dcat076@student.ptithcm.edu.vn` | [shinmagicc](https://github.com/shinmagicc) |
| N25DCAT079 | Đặng Quang Huy | `n25dcat079@student.ptithcm.edu.vn` | [Kurookani](https://github.com/Kurookani) |

## 2. Technology and repository contents

- Database: MySQL with InnoDB, CHECK constraints, triggers, views, indexes, stored procedures, and roles. The optional Docker configuration pins MySQL `8.0.42`.
- Workflow write connections: `READ COMMITTED` isolation.
- Backend: Flask; Python `3.13` was used for the local demo.
- Drivers: `mysql-connector-python` for the web app and `PyMySQL[rsa]==1.1.2` for database test utilities.
- Database name: `mini_upwork`; 11 business tables.

Archived evidence includes runs on servers reporting both `8.0.42` and `26.7.0`; these records do not determine the version currently running on another machine. Check it with `SELECT VERSION();` in Workbench.

Application paths below are relative to [Freelance_Marketplace_Ecosystem_SQL](Freelance_Marketplace_Ecosystem_SQL).

| Path | Purpose |
|---|---|
| `main.py` | Flask routes and Freelancer selection |
| `app/db.py` | Read, Client, Freelancer, and payment-service connections |
| `app/templates/` | Web pages and numeric Freelancer ID controls |
| `sql/01_schema.sql` | Tables, keys, and CHECK constraints |
| `sql/02_triggers.sql` | Integrity and workflow triggers |
| `sql/03_views_indexes.sql` | Reporting views and indexes |
| `sql/04_procedures.sql` | Stored procedure API |
| `sql/05_seed.sql` | Base fictional dataset |
| `sql/06_queries.sql` | 12 advanced queries |
| `sql/07_security.sql` | Roles and initially locked MySQL accounts |
| `sql/08_seed_1000_jobs.sql` | Expanded jobs and user profiles |
| `sql/09_verify_counts.sql` | Exact row counts |
| `INSTALL_DATABASE.sql` | Complete installation bundle |
| `SAMPLE_DATA.sql` | Base and expanded data bundle, without schema installation |
| `SETUP_LOCAL_DEMO.sql` | Unlocks 7 demo users and the payment-service account |
| `tests/` | Database regression, performance, dataset, and web selection tests |
| `evidence/` | Expected counts and recorded execution results |
| `docs/` | Modeling, normalization, security, and audit documentation |
| `requirements.txt` | Python dependencies |
| `compose.yaml` | Optional MySQL container exposed locally on port `3307` |

Additional documents:

- [Project report](Freelance_Marketplace_Ecosystem_G3.docx)
- [Presentation and SQL defense workflow](Workflow_Thuyet_trinh_va_Bao_ve_SQL_G3.docx)
- [Dataset guide](Freelance_Marketplace_Ecosystem_SQL/README.md)
- [Windows walkthrough](tutorial.md)

## 3. Install the database

Use MySQL Workbench and an administrative connection with privileges to create schemas, triggers, routines, roles, and accounts.

For a fresh database:

1. Select **File → Open SQL Script** and open [INSTALL_DATABASE.sql](Freelance_Marketplace_Ecosystem_SQL/INSTALL_DATABASE.sql).
2. Run the complete file. Stop and resolve the first error if one occurs.
3. Refresh **Schemas** and check `mini_upwork`.
4. The final queries show the row counts. A clean installation of the current fixture is expected to contain **8,223 rows**, including **748 users** and **1,008 jobs**.
5. Run [SETUP_LOCAL_DEMO.sql](Freelance_Marketplace_Ecosystem_SQL/SETUP_LOCAL_DEMO.sql) in the administrative connection to set demo passwords, unlock accounts, and select their default roles.

Do not rerun the installation or seed bundles on a populated demo database. The setup script can be rerun to restore demo account passwords; it does not reload the business data.

### Alternative: modular installation

On a fresh database, run these files from `sql/` in order:

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

Then run `SETUP_LOCAL_DEMO.sql`. Run `sql/06_queries.sql` separately to demonstrate the advanced queries.

`SAMPLE_DATA.sql` combines `05_seed.sql` and `08_seed_1000_jobs.sql`. Use it only after installing the schema, triggers, views, and procedures while the business tables are empty. Do not also load it after running `INSTALL_DATABASE.sql`.

## 4. Prepare Python and start the web application

From the repository root, open PowerShell:

```powershell
Set-Location .\Freelance_Marketplace_Ecosystem_SQL
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

If already inside the application directory, omit `Set-Location`. If `python` is not found but the Windows Python launcher is available, use `py -3.13 -m venv .venv` instead.

Start the MySQL service, install the database, and run the account setup script before starting Flask. Set the actual MySQL connection details in the same PowerShell window:

```powershell
$env:DB_HOST = 'localhost'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$mysqlPassword = Read-Host 'Enter the MySQL root password' -AsSecureString
$env:DB_PASSWORD = [System.Net.NetworkCredential]::new('', $mysqlPassword).Password
.\.venv\Scripts\python.exe main.py
```

Use port `3307` instead if connecting to the container from `compose.yaml`. Calling the virtual environment's Python directly does not require activation or an execution-policy change.

Open [http://127.0.0.1:5000](http://127.0.0.1:5000). Keep PowerShell open. To apply Python/template changes, stop Flask with **Ctrl+C**, run the last command again, and refresh the browser with **Ctrl+F5**.

The read connection uses `DB_USER` and `DB_PASSWORD`. Workflow writes use the separate MySQL accounts configured in `app/db.py`; the current classroom demo expects their passwords to match the setup script.

## 5. Demo accounts and current web scope

[SETUP_LOCAL_DEMO.sql](Freelance_Marketplace_Ecosystem_SQL/SETUP_LOCAL_DEMO.sql) unlocks these accounts, restricted to `localhost`:

| Purpose | Business IDs | MySQL accounts | Demo password |
|---|---|---|---|
| Client | 1, 2, 3 | `client_1`, `client_2`, `client_3` | `Client1@123` |
| Freelancer | 4, 5, 6, 7 | `freelancer_4` through `freelancer_7` | `Freelancer4@123` |
| Payment service | Not a business user | `payment_service` | `Payment@123` |

These are **7 demo users plus 1 service account**, separate from the **748 fictional profiles** in the `users` table. The remaining profiles do not automatically have usable MySQL accounts. This prototype has no complete registration/login system; choosing an ID is a demo control, not authentication.

- **Post New Job** accepts a Client ID. Clients 1–3 can post after account setup.
- **My Contracts**, Client milestone creation, and Client milestone approval still use **Client 1** in `main.py`. Use Client 1 for a complete web demonstration; unlocking Clients 2 and 3 does not make those pages switch users.
- **Submit Proposal** accepts a numeric Freelancer ID from **4 to 7**.
- **My Proposals** and **My Milestones** have numeric Freelancer ID controls. Enter the ID and click **View**. The browser session remembers it, and the action forms send the displayed ID to the stored procedures.
- After submitting as Freelancer 5, for example, My Proposals uses ID 5. You can enter ID 4 and click View to switch back.

## 6. Demonstration workflow

For a complete web demonstration, post a new job as **Client 1**, then use any unlocked Freelancer from **4 to 7**.

1. **Client Dashboard → Post New Job:** enter Client ID `1`, category, title, description, budgets, and an optional future deadline.
2. **Freelancer Dashboard → Submit Proposal:** enter the Freelancer ID, proposed amount, estimated days, and cover letter.
3. **Client Dashboard → View Proposals → Select Proposal:** choose the desired proposal. Its status becomes `CLIENT_ACCEPTED`.
4. **Freelancer Dashboard → My Proposals:** enter the ID of the selected Freelancer and click **View**. Click **Confirm Proposal** on the `CLIENT_ACCEPTED` row.
5. Confirmation changes the proposal to `CONFIRMED`; the database trigger creates the Contract.
6. **Client Dashboard → My Contracts → Milestones:** open the new contract and use **Add Milestone**. The milestone is created by the Client, not automatically by selecting a proposal.
7. **Freelancer → My Milestones:** use the same Freelancer ID. Click **Start Work**, then **Mark Completed**.
8. The Client approves the completed milestone, then records a simulated payment.
9. Open `/reports` to view the reporting summaries.

### If Confirm Proposal or a milestone is missing

| Symptom | Check |
|---|---|
| No Confirm button | It appears only for `CLIENT_ACCEPTED`; `PENDING` is not yet selected, while `CONFIRMED` is already confirmed. |
| The selected proposal is absent | In My Proposals, enter the Freelancer ID the Client actually selected and click View. |
| No Contract after Client selection | The Freelancer must confirm the proposal first. |
| Contract missing in My Contracts | That page currently filters to Client 1. Jobs posted by another Client are outside that view. |
| No Freelancer milestone | The Client must create a milestone under the confirmed Contract; then view the assigned Freelancer's ID. |
| Access denied or account locked | Rerun `SETUP_LOCAL_DEMO.sql` as an administrator on the same MySQL server and check the configured host and port. |

## 7. Current sample-data counts

These are the clean fixture counts from [install_database_expected_counts.json](Freelance_Marketplace_Ecosystem_SQL/evidence/install_database_expected_counts.json), before extra demo actions:

| Table | Rows |
|---|---:|
| `users` | 748 |
| `clients` | 143 |
| `freelancers` | 605 |
| `skills` | 26 |
| `freelancer_skills` | 610 |
| `job_categories` | 11 |
| `jobs` | 1,008 |
| `proposals` | 1,811 |
| `contracts` | 605 |
| `milestones` | 1,810 |
| `payments` | 846 |
| **Total across all 11 tables** | **8,223** |

People and companies are fictional, emails use `example.test`, and sample amounts are in USD. The total includes subtype rows in `clients` and `freelancers`; it is not a count of distinct people.

To inspect actual counts in Workbench, run [sql/09_verify_counts.sql](Freelance_Marketplace_Ecosystem_SQL/sql/09_verify_counts.sql). Posting jobs, submitting proposals, and other demo actions increase the counts.

With the connection variables from Section 4 set, run the clean-fixture verifier from the application directory:

```powershell
.\.venv\Scripts\python.exe tests\verify_large_dataset.py
```

It reads the database, compares the current expected counts, checks integrity, and executes the 12 advanced queries. On success it writes `evidence/install_database_results.json`. A database containing extra demo records will not match the clean-fixture counts; do not delete demo data just to make that fixed-count check pass.

## 8. Tests and recorded evidence

### Web selection regression tests

These use mocked database connections and do not change MySQL data:

```powershell
.\.venv\Scripts\python.exe -B -m unittest discover -s tests -p test_freelancer_selection.py -v
```

They cover IDs 4–7, the Confirm button's status condition, remembering the selection, confirming as the displayed Freelancer, and milestone actions. They do not establish that the live MySQL installation or a browser session has been tested.

### Database regression and security tests

Run these only on an isolated test server with a disposable `mini_upwork` database. `--install` drops and rebuilds that schema; test execution without `--install` can also modify data. Keep `DB_HOST`, `DB_PORT`, `DB_USER`, and `DB_PASSWORD` pointed at the test instance.

```powershell
.\.venv\Scripts\python.exe tests\run_tests.py --install --security
```

Optional performance checks on the test instance:

```powershell
.\.venv\Scripts\python.exe tests\run_performance.py
```

[The verification summary dated 2026-11-15](audit_test_results/verification_2026-11-15/verification_summary.json) records **104 passing checks** on the base fixture, including 20 RBAC checks. [The clean installation evidence](Freelance_Marketplace_Ecosystem_SQL/evidence/install_database_results.json) records the expanded dataset. These are archived results for their stated environments, not a claim that all database suites have been rerun after every web change.

## 9. Design and functional limits

Workflow writes call stored procedures through role-specific accounts. The procedures, triggers, and constraints enforce ownership, state transitions, and integrity; the demo roles are not granted direct table modification privileges.

The normalized `payments` table stores `payment_id`, `milestone_id`, `payment_status`, `payment_method`, and a generated unique `paid_milestone_id`. Payer, payee, and amount are derived through milestones and contracts.

Payments record simulated statuses only. Real payment gateways, escrow, refunds, and production user authentication are not implemented. The web server binds to `127.0.0.1:5000` for the local classroom demonstration.
