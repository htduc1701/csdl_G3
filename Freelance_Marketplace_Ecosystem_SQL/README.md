# Mini-Upwork G3 — Sample Dataset

See the [main README](../README.md) for project members, installation, Python setup, demo accounts, the web workflow, and test commands. Paths below are relative to this directory.

## 1. Dataset and expected counts

The current complete fixture contains **748 fictional users**, split into **143 Clients** and **605 Freelancers**, and **1,008 jobs**. Across the 11 business tables, the expected total is **8,223 rows**.

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
| **Total** | **8,223** |

The counts come from [evidence/install_database_expected_counts.json](evidence/install_database_expected_counts.json) and apply before adding demo records. Client and Freelancer subtype rows are included in the total; 8,223 is not the number of distinct people.

Names and companies are fictional, emails use `example.test`, and amounts are demo USD. The records are generated sample data, not real marketplace transactions.

## 2. Installation options

For a fresh database, run [INSTALL_DATABASE.sql](INSTALL_DATABASE.sql) using an administrative connection in MySQL Workbench. Stop at the first error. The bundle installs the schema, routines, roles, initially locked accounts, and the full dataset, then displays row counts.

Run [SETUP_LOCAL_DEMO.sql](SETUP_LOCAL_DEMO.sql) afterward. It sets passwords and unlocks Clients **1–3**, Freelancers **4–7**, and the **payment_service** account. The 748 business profiles do not automatically provide 748 MySQL logins.

Use Client **1** for a complete web demonstration: My Contracts and the Client milestone actions currently remain fixed to that ID. Freelancer selection supports numeric IDs **4–7** in My Proposals and My Milestones. A selected proposal must be confirmed by its Freelancer before the Contract is created; the Client then adds milestones manually.

Do not rerun the installation bundle or seeds on a populated demo database.

### Loading sample data separately

[SAMPLE_DATA.sql](SAMPLE_DATA.sql) combines:

```text
sql/05_seed.sql
sql/08_seed_1000_jobs.sql
```

Use this bundle only after installing `01_schema.sql` through `04_procedures.sql` while the business tables are empty. Do not load both it and the data already included in `INSTALL_DATABASE.sql`.

If only the base fixture from `05_seed.sql` exists, run `08_seed_1000_jobs.sql` once to add the expanded dataset. The extension refuses occupied fixture ID ranges and rolls back its transaction on error. It is not a general migration for a database already containing expanded fixture or custom data.

## 3. Verification

To inspect the current database's row counts in Workbench, run [sql/09_verify_counts.sql](sql/09_verify_counts.sql).

After setting the connection environment variables as described in the [main README](../README.md), run:

```powershell
.\.venv\Scripts\python.exe tests\verify_large_dataset.py
```

The verifier reads the expected counts from `evidence/install_database_expected_counts.json`, checks all 11 tables, nine integrity conditions, sample-data content, and the 12 advanced queries. It does not change database data. On success, it writes [evidence/install_database_results.json](evidence/install_database_results.json).

Extra demo jobs, proposals, contracts, milestones, or payments cause the fixed-count check to differ from the clean fixture. Use the row-count SQL to inspect such a database without requiring a fixture match.

## 4. Coverage and evidence

The fixture includes jobs without proposals, proposals awaiting Client selection or Freelancer confirmation, active/completed contracts, milestone states, and pending/failed/successful payment attempts. It includes failed payment attempts followed by a successful retry without allowing two successful payments for the same milestone.

- [Current expected counts](evidence/install_database_expected_counts.json)
- [Recorded complete-installation result](evidence/install_database_results.json)
- [Earlier dataset report](docs/large_dataset_report.md) and [earlier evidence](evidence/large_dataset_results.json), which may describe an older fixture
- [Base-fixture verification summary](../audit_test_results/verification_2026-11-15/verification_summary.json), recording 104 passing checks including 20 RBAC checks

Archived evidence describes the environment and dataset used for that run. The optional [compose.yaml](compose.yaml) pins MySQL `8.0.42`; some archived local results report `26.7.0`. Check the running server with `SELECT VERSION();`.

Database regression tests are separate from this read-only verifier. `tests/run_tests.py --install` drops and rebuilds `mini_upwork`, and the suite can change data even without that flag. Run it only on an isolated test instance. See the main README for the mocked web selection tests, which do not access the real database.
