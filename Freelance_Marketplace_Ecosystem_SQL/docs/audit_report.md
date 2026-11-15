# Audit report

Audited all four supplied files. The two PDFs contain2 pages each. The report contains16 BRs and11 entities. No application source, SQL or DBMS configuration was present. Attachment suffixes differ from prompt names; no supplied file was unreadable.

| ID | File and location | Severity | Finding | BR | Resolution | Status |
|---|---|---|---|---|---|---|
| A-01 | Report §2.2 USER vs §3.1 | High | Logical mapping omits user_type although dictionary includes it. | BR-02 | Add discriminator to schema, dictionary and diagram. | Fixed |
| A-02 | Report §2.1 specialization and §3.1 | Critical | A type CHECK alone does not enforce disjoint or total specialization. | BR-02 | Automatic subtype creation, immutable type/IDs, subtype insert/type guards and retention. | Fixed |
| A-03 | Report §1 requirements | Medium | Functional and non-functional requirements not separated per teaching standard p1. | All | Add data-centered FRs, scoped user requirements and measurable NFRs. | Fixed |
| A-04 | Report Figure1 and §2.1 | High | EER claimed without formal specialization symbols or required industry mapping; diagram omits discriminator and method. | BR-02/16 | Replace with physical IE Crow Foot diagrams plus mapping appendix. | Fixed |
| A-05 | Report §2.1 cardinalities | High | Two subtype links read as unconditional1:1; proposal-contract optionality reversed. | BR-02/11 | Each user has0..1 per subtype, exactly1 across union; each contract exactly1 proposal, each proposal0..1 contract. | Fixed |
| A-06 | Report §2.2 and §3.11 | Critical | UNIQUE milestone_id permits only one attempt, contradicting successful-only uniqueness and FAILED retry. | BR-15/16 | Many attempts; generated paid_milestone_id UNIQUE only for PAID. | Fixed |
| A-07 | Report §1.1 vs BR-15 and §3.10 | High | COMPLETED described as sufficient despite client approval requirement. | BR-15 | Explicit PENDING->IN_PROGRESS->COMPLETED->APPROVED workflow; payment only after APPROVED. | Fixed |
| A-08 | Report §3.11 payer/payee | Critical | PAYMENT duplicated the parties and amount determined by the linked contract and milestone. | BR-16 | Derive payer and payee from CONTRACT and amount from MILESTONE. | Fixed |
| A-09 | Report §3.8 | High | Unique job-freelancer pair mentioned but not in dictionary. | BR-08 | Named composite UNIQUE; negative and positive tests. | Fixed |
| A-10 | Report §3.8 selected proposal | Critical | No enforcement of selected proposal uniqueness. | BR-10 | Generated selected_job_id UNIQUE for CLIENT_ACCEPTED and CONFIRMED. | Fixed |
| A-11 | Report §3.9 | Critical | Independent FKs permit mismatched client/freelancer and pre-confirmation contract. | BR-11/12 | Ordered proposal transitions, atomic contract creation trigger, matching parties and immutable references. | Fixed |
| A-12 | Report §3.10 amount | Critical | Cross-row total cannot be enforced by a row CHECK. | BR-14 | Parent contract row lock, aggregate guard under READ COMMITTED, contract update guard; procedure-first access. | Fixed with documented isolation contract |
| A-13 | Report §3.7 deadline | Medium | Creation reference for deadline is undefined and absent from schema. | Dates | Add immutable created_at and deterministic CHECK deadline>DATE(created_at). | Fixed |
| A-14 | Report §3 date/status domains | Medium | Vague skill levels, dates, method examples and statuses lack enforceable domains. | BR-14/16 | Explicit CHECK domains, DECIMAL values and milestone/contract date guards. | Fixed |
| A-15 | Report §2.3 | High | BCNF claimed from surrogate keys without a complete candidate key and FD analysis. | Normalization | Document candidate keys and FDs for all 11 logical business relations, with generated columns projected out. | Fixed |
| A-16 | Report §2.3 PAYMENT with retry design | High | In the former PAYMENT design, milestone_id determined amount and parties while multiple attempts could share one milestone. | BR-16/Normalization | Store method and status per attempt and derive amount and parties from the related records. | Fixed |
| A-17 | Report §5.1 test table | Critical | PASS and error outcomes claimed without executable SQL/evidence. | BR-02/08/14 | Replace placeholders with actual measured tests and engine errors. | Fixed |
| A-18 | Report §4.1/4.2 | High | DDL, seed, views, queries and performance are placeholders. | All | Nine modular SQL scripts and 12 reporting queries. Archived evidence includes query output, EXPLAIN ANALYZE and a scale benchmark. | Fixed |
| A-19 | Report §5.2 | High | RBAC placeholder despite template requiring GRANT/REVOKE. | Security | Native DB roles, locked per-actor accounts, definer APIs and actual privilege tests. | Fixed |
| A-20 | Report schema naming | Low | Uppercase entities vs plural physical names not explicitly mapped. | Style | Use lowercase plural snake_case physical names and an11-entity mapping appendix. | Fixed |
| A-21 | Workspace initial inventory | Low | The original materials did not specify the database engine. | Scope | Document the demo environment and regression evidence for MySQL Community Server 26.7.0. | Resolved |
| A-22 | Implementation operational boundary | Medium | Locking parent tables in trigger can reject INSERT SELECT from that same parent (MySQL1442). | BR-14 | Supported procedures use VALUES; READ COMMITTED standalone transaction boundary documented and tested. | Documented limitation |

## Verification

The 2026-11-15 clean installation on MySQL 26.7.0 verified 8,223 rows, 748 users and 1,008 jobs after seeds 05 and 08. See the [installation results](../evidence/install_database_results.json). The [dataset report](large_dataset_report.md) retains the 7,223-row historical results.

See the [current 3NF audit](../../audit_report_3NF.md#verification) for the scope of the regression evidence and the [normalization analysis](normalization.md) for the logical BCNF conclusion.
