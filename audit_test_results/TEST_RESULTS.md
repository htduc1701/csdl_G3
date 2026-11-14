# Test results

**Run date:** 2026-11-14 (Asia/Saigon)

## Fresh database run

The current test runner was run against the disposable schema `mini_upwork_codex_test_20261114`, then that schema was dropped. The run produced **84/84 passing assertions**: 72 integrity, workflow, concurrency, and invariant checks plus 12 query result assertions. MySQL reported version 26.7.0 and READ-COMMITTED; this differs from the documented MySQL 8.0.42 target. See [the fresh run report](FRESH_TEST_RUN_2026-11-14.md) and its JSON evidence under `fresh_test_20261114/evidence/`.

The duplicate-email input in TC-04 was corrected to use an address present in the fixture. An intermediate invocation accidentally targeted `mini_upwork` and stopped during the first concurrency case; the run report documents what was checked afterward and the remaining uncertainty about proposal 10's pre-run status.

## Review feature removal

The project SQL/EER and application source already contained no review/rating feature. The connected legacy schema did contain `contract_reviews` (120 rows) and its dependent `v_freelancer_ratings` view. At the user's request, both were dropped directly from `mini_upwork`; a post-cleanup query confirmed zero remaining objects. No migration file was retained.

## Current checks

| Check | Result | Evidence / limitation |
|---|---|---|
| Parse project Python source with `ast` | PASS, 6 source files | Parsed in memory; excluded `.venv` and `__pycache__`. |
| Load Jinja templates | PASS, 12 templates | Flask/Jinja environment loaded each template. |
| Missing milestone HTTP handling | PASS, 3 requests | Mocked database returned no row; approval POST, payment GET, payment POST each returned 404. |
| Local Markdown links in root README/tutorial and project README | PASS | All inspected local link targets exist. |
| Computer Use / MySQL Workbench | PASS (read-only inspection) | Queried live metadata and table counts. A separate intermediate runner attempt targeted the live schema and stopped at its first concurrency case; see the incident note in the fresh run report. |
| DOCX scope verification | PASS (structural) | Updated only Section 5; all text and tables outside Section 5 matched the pre-edit structure. Visual rendering is not verified. |
| Workbench connection and server metadata | PASS (read-only) | Connected session showed `root@localhost:3306`, schema `mini_upwork`, server version `26.7.0`, `REPEATABLE-READ`, and SQL mode `ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION`. This is not the documented MySQL 8.0.42 / READ COMMITTED test target. |
| Live schema/table inventory | PASS | Initially found 12 base tables, including legacy `contract_reviews`; direct cleanup removed that table and `v_freelancer_ratings`. The live schema now has no review/rating objects. |
| Live row counts | PASS (read-only before cleanup) | Before cleanup, 11 expected tables totaled 7,245 vs documented fixture 7,223 (+22), and `contract_reviews` held 120 rows. The requested cleanup permanently removed those 120 rows; the remaining business-table counts were not changed. |
| `tests/run_tests.py` current suite | PASS, 84/84 assertions | Ran on disposable schema; 72 integrity/workflow/concurrency/invariant checks and 12 query assertions. Fresh evidence is in `fresh_test_20261114/evidence/`. |
| Large-fixture verification | NOT RUN | Requires a separate populated fixture and writes large-fixture evidence. |
| RBAC security suite | NOT RUN | Optional suite provisions and locks MySQL accounts; not run in this pass. |
| Query assertions | PASS, 12/12 | Run by the current test runner against the re-seeded disposable schema. |
| Performance benchmarks | NOT RUN | Separate runner creates and later drops `mini_upwork_perf`; not run in this pass. |
| Browser/live end-to-end workflow | NOT RUN | The Flask application and browser workflow were not launched. |

## Environment

- Python: 3.13.7
- Flask: 3.1.3
- mysql-connector-python: 26.7.0
- PyMySQL: 1.2.3
- Connected server: MySQL Workbench reported server version 26.7.0 at `localhost:3306`, with REPEATABLE-READ. It is outside the project's documented MySQL 8.0.42 / READ COMMITTED test target.
- `evidence/environment.json` historically records MySQL 8.0.42 and READ-COMMITTED but is not current verification.
- Docker Compose: unavailable (`docker` command not found).

## Historical evidence (not rerun)

The repository contains 72 rows in `evidence/test_results.json` (72 marked passed), 20 rows in `evidence/security_results.json` (20 marked passed), and 12 rows in `evidence/query_results.json` (12 marked passed). `verification_summary.json` aggregates 104 passes and zero failures. `large_dataset_results.json` records 7,223 rows and zero stated invariant violations; `performance_results.json` records a MySQL 8.0.42 benchmark.

These files have no reliable run timestamp in their JSON structure. They were read, not changed. They are historical evidence and do not establish that the current checkout passes a fresh MySQL run.
