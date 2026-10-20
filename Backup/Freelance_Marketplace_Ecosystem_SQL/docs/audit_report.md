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
| A-08 | Report §3.11 payer/payee | Critical | Being a contract party is weaker than correct client payer and freelancer payee. | BR-16 | Trigger validates exact participants and amount against milestone/contract. | Fixed |
| A-09 | Report §3.8 | High | Unique job-freelancer pair mentioned but not in dictionary. | BR-08 | Named composite UNIQUE; negative and positive tests. | Fixed |
| A-10 | Report §3.8 selected proposal | Critical | No enforcement of selected proposal uniqueness. | BR-10 | Generated selected_job_id UNIQUE for CLIENT_ACCEPTED and CONFIRMED. | Fixed |
| A-11 | Report §3.9 | Critical | Independent FKs permit mismatched client/freelancer and pre-confirmation contract. | BR-11/12 | Ordered proposal transitions, atomic contract creation trigger, matching parties and immutable references. | Fixed |
| A-12 | Report §3.10 amount | Critical | Cross-row total cannot be enforced by a row CHECK. | BR-14 | Parent contract row lock, aggregate guard under READ COMMITTED, contract update guard; procedure-first access. | Fixed with documented isolation contract |
| A-13 | Report §3.7 deadline | Medium | Creation reference for deadline is undefined and absent from schema. | Dates | Add immutable created_at and deterministic CHECK deadline>DATE(created_at). | Fixed |
| A-14 | Report §3 date/status domains | Medium | Vague skill levels, dates, method examples and statuses lack enforceable domains. | BR-14/16 | Explicit CHECK domains, DECIMAL values and milestone/contract date guards. | Fixed |
| A-15 | Report §2.3 | High | BCNF claimed from surrogate keys; no complete candidate key and FD analysis. | Normalization | Formal FD/key table; ten tables meet BCNF under stated FDs; payments is controlled denormalization. | Claim corrected |
| A-16 | Report §2.3 PAYMENT with retry design | High | milestone_id->amount,payer_id,payee_id violates3NF when milestone_id is not unique. | BR-16/Normalization | Keep explicit transfer evidence and retry history; document exception and normalized11-table alternative. | Unresolved strict3NF exception; requires design tradeoff |
| A-17 | Report §5.1 test table | Critical | PASS and error outcomes claimed without executable SQL/evidence. | BR-02/08/14 | Replace placeholders with actual measured tests and engine errors. | Fixed |
| A-18 | Report §4.1/4.2 | High | DDL, seed, views, queries and performance are placeholders. | All | Seven SQL scripts,12 queries with actual output, EXPLAIN ANALYZE, scale benchmark. | Fixed |
| A-19 | Report §5.2 | High | RBAC placeholder despite template requiring GRANT/REVOKE. | Security | Native DB roles, locked per-actor accounts, definer APIs and actual privilege tests. | Fixed |
| A-20 | Report schema naming | Low | Uppercase entities vs plural physical names not explicitly mapped. | Style | Use lowercase plural snake_case physical names and an11-entity mapping appendix. | Fixed |
| A-21 | Workspace initial inventory | Low | Prompt filenames include extra(1) suffixes absent in actual attachments; no SQL/repository DBMS exists. | Scope | Read all four supplied equivalents; choose and actually test MySQL8.0.42. | Resolved |
| A-22 | Implementation operational boundary | Medium | Locking parent tables in trigger can reject INSERT SELECT from that same parent (MySQL1442). | BR-14 | Supported procedures use VALUES; READ COMMITTED standalone transaction boundary documented and tested. | Documented limitation |

## Verification

72 integrity/workflow/concurrency tests,20 RBAC tests and12 query assertions passed on MySQL8.0.42. See evidence JSON and readable test/query reports. Tested guarantees cover provided cases and the supported procedure access path, not arbitrary DBA privilege misuse.

## Remaining assessment risk

PAYMENT intentionally retains milestone-determined participants and amount, so strict all-table3NF/BCNF is not claimed. This conflicts with the strongest normalization grading target while preserving the specified explicit record and failed retries. The report provides an11-entity normalized alternative; no silent field removal was performed. Encryption at rest and restore-drill targets are requirements, not demonstrated deployments. Semester Phase4 UI, defense and peer evaluation remain out of this task scope.
