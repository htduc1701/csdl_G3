# Mini-Upwork G3 - Synthetic Sample Dataset

See the [main README](../README.md) and the [Windows setup guide](../tutorial.md) to run the Flask application and demonstrate the Client-Freelancer workflow.

Paths below are relative to `Freelance_Marketplace_Ecosystem_SQL`.

## 1. Environment and Dataset

- MySQL with InnoDB; `READ COMMITTED` isolation for workflow write operations.
- **11 business tables**, containing **7,223 records**, including **1,008 jobs**.
- The expanded dataset adds 1,000 jobs to the base sample dataset.
- People and companies are fictional; email addresses use `example.test`; monetary amounts are in USD. Descriptions and skills are assembled across eight professional categories. This is template-generated data, not real transactions or data collected from real people.
- The optional Compose configuration uses MySQL `8.0.42` on host port `3307`. A direct local installation typically uses port `3306`.

## 2. Fresh Installation with MySQL Workbench

1. Connect to MySQL with an administrative account authorized to create schemas, triggers, views, stored procedures, roles, and accounts.
2. Select **File > Open SQL Script** and open [INSTALL_DATABASE.sql](INSTALL_DATABASE.sql).
3. Run the entire script, stopping if any error occurs. Refresh **Schemas > mini_upwork > Tables**.
4. The final section already verifies row counts; you can rerun [sql/09_verify_counts.sql](sql/09_verify_counts.sql). For the original dataset, `total_rows` is **7,223**.
5. Run [SETUP_LOCAL_DEMO.sql](SETUP_LOCAL_DEMO.sql) as an administrator to use the web application with Client ID **1** and Freelancer ID **4**.
6. Run [sql/06_queries.sql](sql/06_queries.sql) to view the 12 advanced queries.

The installation bundle is intended for a fresh database only. Do not ignore errors and continue importing. Sample MySQL accounts are created in a locked state by `07_security.sql`; `SETUP_LOCAL_DEMO.sql` sets sample passwords matching `app/db.py` and unlocks the three accounts used for the local demo.

## 3. Importing Sample Data Separately

[SAMPLE_DATA.sql](SAMPLE_DATA.sql) contains `INSERT ... VALUES` statements with fictional people, companies, professional titles, jobs, proposals, and milestones.

Run it only after installing `sql/01_schema.sql` through `sql/04_procedures.sql` while the business tables are empty. It already includes both `05_seed.sql` and `08_seed_1000_jobs.sql`; do not load it again if `INSTALL_DATABASE.sql` has been used.

## 4. Extending the Base Dataset

If `01_schema.sql` through `05_seed.sql` are already installed, run only [sql/08_seed_1000_jobs.sql](sql/08_seed_1000_jobs.sql), followed by [sql/09_verify_counts.sql](sql/09_verify_counts.sql).

Do not rerun `INSTALL_DATABASE.sql` or `05_seed.sql` on populated tables. The extension runs once, preserves the existing dataset, and rolls back added data if an error occurs. It refuses to run if its intended ID ranges are already occupied.

If custom data exists beyond the base dataset, or demo actions have already been performed, the actual total may differ from 7,223. Run the extension in a separate administrative session with `READ COMMITTED` isolation.

## 5. Verifying the Expanded Dataset

Create a Python environment and install dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Set the connection details and run the verifier. Change the port to `3307` when using the project's Compose configuration.

```powershell
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$mysqlPassword = Read-Host 'Enter the MySQL root password' -AsSecureString
$env:DB_PASSWORD = [System.Net.NetworkCredential]::new('', $mysqlPassword).Password
.\.venv\Scripts\python.exe tests\verify_large_dataset.py
```

The verifier only reads the database and writes results to `evidence/large_dataset_results.json`. It checks row counts for all 11 tables, the 7,223-row total, nine integrity conditions with zero violations, five data-content checks, and execution of all 12 advanced queries.

Expected and actual results for the 75-row base dataset do not apply to the large dataset. The fixed-count verifier may report a mismatch after demo data has been added.

**Warning:** `tests/run_tests.py --install` targets the base dataset and includes dropping and rebuilding the `mini_upwork` schema. Run it only on a separate MySQL instance dedicated to testing. Running without `--install` can still change data during test cases; do not run it on a demo database that must be preserved.

## 6. Data Coverage and Recorded Results

The dataset includes jobs without proposals, proposals awaiting selection or confirmation, contracts in `ACTIVE`/`COMPLETED` states, four milestone states, and three payment states.

It includes a `FAILED` payment followed by a successful `PAID` retry, without two `PAID` payments for the same milestone. Subtype records and contracts are still created by triggers; constraints remain enabled.

- [docs/large_dataset_report.md](docs/large_dataset_report.md) and [evidence/large_dataset_results.json](evidence/large_dataset_results.json) contain evidence from a previous large-dataset verification run.
- The [test log dated November 14, 2026](../audit_test_results/FRESH_TEST_RUN_2026-11-14.md) records 72 passing integrity, workflow, and concurrency checks plus 12 passing query-result assertions, totaling **84/84**, on a server reporting version `26.7.0` using the base dataset in a disposable schema. That run excludes RBAC, large-dataset, and performance tests and does not certify compatibility with MySQL `8.0.42`.
- Other evidence files may refer to older datasets or environments; they do not establish that every suite has been rerun on the large dataset.
- Expanding the dataset does not change the normalized `payments` design. The web payment workflow only records simulated statuses.
- The 240 additional profiles do not automatically create 240 MySQL accounts. Sample MySQL accounts remain restricted to `localhost` as defined in `sql/07_security.sql`; fictional profiles do not provide actual login access.

Record counts refer to rows stored in tables, not lines of SQL text.
