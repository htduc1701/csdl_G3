# Fresh test run — 2026-11-14

## Result

- **84/84 assertions passed:** 72 integrity, workflow, concurrency, and invariant checks; 12 query result assertions.
- **MySQL:** 26.7.0; transaction isolation: READ-COMMITTED; SQL mode: `ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION`.
- Executed with the current test runner against disposable schema `mini_upwork_codex_test_20261114`; that schema was removed after the run. The populated `mini_upwork` schema was not targeted by this successful run.
- `TC-04` was corrected in `Freelance_Marketplace_Ecosystem_SQL/tests/run_tests.py` to submit the exact email present in the fixture, so the duplicate-email assertion tests a real duplicate.

## Fresh evidence

- `evidence/test_results.json` — 72 checks, 72 passed.
- `evidence/query_results.json` — 12 query assertions, 12 passed, with EXPLAIN and timing results.
- `evidence/environment.json` — server and index metadata.
- `evidence/verification_summary.json` — totals and explicit status of optional suites.

The evidence files above were produced by this run. Historical security, performance, and large-fixture evidence was excluded from this folder. The optional RBAC suite and large-fixture/performance runners were not run.

## Compatibility limit

The connected server reports MySQL **26.7.0**, while the project documents MySQL 8.0.42. This run is fresh and passes on the connected server, but does not certify MySQL 8.0.42 behavior.

## Incident note

An intermediate invocation used the original runner's hard-coded `mini_upwork` target and stopped during its first concurrency case. The individual `test()` checks roll back, but the runner performs a proposal status update outside that rollback before entering concurrency tests. Afterward, the live schema's observed counts matched the pre-run snapshot for the checked tables (users 248, proposals 1,816, contracts 608, milestones 1,813, payments 850); proposal 10 was observed as `CLIENT_ACCEPTED` with no contract. Its row-level status was not captured before that invocation, so a change to that field cannot be ruled out.

After the intermediate attempt, no further writes were made to the live schema until the user's later request to remove the review feature. That direct cleanup dropped `v_freelancer_ratings` and `contract_reviews` (120 rows); completion is recorded in `TEST_RESULTS.md`.
