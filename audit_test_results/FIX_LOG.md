# Fix log

## F-02 — Return 404 for missing milestones

- **File:** `Freelance_Marketplace_Ecosystem_SQL/main.py`
- **Locations:** `approve_milestone` and `record_payment`.
- **Before:** Each route fetched a milestone and immediately indexed the result. Unknown IDs could raise an exception and return HTTP 500.
- **Cause:** No not-found branch after the database lookup.
- **Change:** Abort with HTTP 404 when the lookup returns no row.
- **Verification:** Flask test client with a mocked connection returning `None`: approval POST, payment GET, and payment POST each returned 404. No MySQL connection or data write occurred.
- **Impact:** Only invalid/nonexistent milestone requests change; normal workflow behavior is unchanged.

## F-03 — Align normalization and BR-16 documentation

- **Files:** `Freelance_Marketplace_Ecosystem_SQL/docs/normalization.md`, `docs/business_rule_matrix.md`.
- **Before:** Payment normalization text claimed the current payment table stored amount/payer/payee and was not 3NF; the BR-16 matrix described a matching explicit-field trigger.
- **Cause:** These passages were not updated after the normalized payment schema was adopted.
- **Change:** Describe the current payment attempt fields, derived parties/amount, generated uniqueness helper, and approval/active-contract guard.
- **Verification:** Compared to `sql/01_schema.sql`, `sql/02_triggers.sql`, `sql/04_procedures.sql`, `docs/business_rules.json`, and the Word payment dictionary. Static Python/template checks still pass after edits.
- **Impact:** Documentation-only; no schema or business behavior changed.

## Preserved baseline changes

At audit start, Git already showed local modifications to root `README.md`, root `tutorial.md`, and `Freelance_Marketplace_Ecosystem_SQL/README.md`. Those edits were not reverted or overwritten. A tracked Python bytecode file changed as a side effect of importing Flask for the route smoke check; it was restored byte-for-byte from the pre-existing committed version because it had no baseline working-tree modification.
