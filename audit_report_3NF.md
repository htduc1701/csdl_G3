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
| A-08 | Report §3.11 payer/payee/amount | Critical | The previous PAYMENT design duplicated payer_id, payee_id and amount even though they are determined by the related milestone/contract. | BR-16/Normalization | Remove payer_id, payee_id and amount from PAYMENT; derive payer from CONTRACT.client_id, payee from CONTRACT.freelancer_id and amount from MILESTONE.amount. Payment triggers validate APPROVED milestone / ACTIVE contract and immutable payment evidence. | Fixed |
| A-09 | Report §3.8 | High | Unique job-freelancer pair mentioned but not in dictionary. | BR-08 | Named composite UNIQUE; negative and positive tests. | Fixed |
| A-10 | Report §3.8 selected proposal | Critical | No enforcement of selected proposal uniqueness. | BR-10 | Generated selected_job_id UNIQUE for CLIENT_ACCEPTED and CONFIRMED. | Fixed |
| A-11 | Report §3.9 | Critical | Independent FKs permit mismatched client/freelancer and pre-confirmation contract. | BR-11/12 | Ordered proposal transitions, atomic contract creation trigger, matching parties and immutable references. | Fixed |
| A-12 | Report §3.10 amount | Critical | Cross-row total cannot be enforced by a row CHECK. | BR-14 | Parent contract row lock, aggregate guard under READ COMMITTED, contract update guard; procedure-first access. | Fixed with documented isolation contract |
| A-13 | Report §3.7 deadline | Medium | Creation reference for deadline is undefined and absent from schema. | Dates | Add immutable created_at and deterministic CHECK deadline>DATE(created_at). | Fixed |
| A-14 | Report §3 date/status domains | Medium | Vague skill levels, dates, method examples and statuses lack enforceable domains. | BR-14/16 | Explicit CHECK domains, DECIMAL values and milestone/contract date guards. | Fixed |
| A-15 | Report §2.3 | High | BCNF was previously claimed from surrogate keys without a complete candidate-key and FD analysis. | Normalization | Formal FD/key table added. All 11 business relations satisfy BCNF under the stated business FDs; generated helper columns are treated as implementation-only attributes. | Fixed |
| A-16 | Report §2.3 PAYMENT with retry design | High | In the previous PAYMENT design, milestone_id -> payer_id, payee_id, amount violated 3NF/BCNF because milestone_id was not unique when retries were allowed. | BR-16/Normalization | Adopt the normalized PAYMENT relation: payments(payment_id PK, milestone_id FK, payment_method, payment_status, paid_milestone_id generated). Derive payer/payee/amount through MILESTONE and CONTRACT while retaining FAILED/PENDING retry history and at most one PAID attempt. | Fixed |
| A-17 | Report §5.1 test table | Critical | PASS and error outcomes claimed without executable SQL/evidence. | BR-02/08/14 | Replace placeholders with actual measured tests and engine errors. | Fixed |
| A-18 | Report §4.1/4.2 | High | DDL, seed, views, queries and performance are placeholders. | All | Seven SQL scripts,12 queries with actual output, EXPLAIN ANALYZE, scale benchmark. | Fixed |
| A-19 | Report §5.2 | High | RBAC placeholder despite template requiring GRANT/REVOKE. | Security | Native DB roles, locked per-actor accounts, definer APIs and actual privilege tests. | Fixed |
| A-20 | Report schema naming | Low | Uppercase entities vs plural physical names not explicitly mapped. | Style | Use lowercase plural snake_case physical names and an11-entity mapping appendix. | Fixed |
| A-21 | Workspace initial inventory | Low | Prompt filenames include extra(1) suffixes absent in actual attachments; no SQL/repository DBMS exists. | Scope | Read all four supplied equivalents; choose and actually test MySQL8.0.42. | Resolved |
| A-22 | Implementation operational boundary | Medium | Locking parent tables in trigger can reject INSERT SELECT from that same parent (MySQL1442). | BR-14 | Supported procedures use VALUES; READ COMMITTED standalone transaction boundary documented and tested. | Documented limitation |

## Verification

After the PAYMENT normalization change, the schema, views, procedures, seed data and reporting queries were rerun successfully on MySQL 8.0.42. TC-39 was updated from payment-amount immutability to payment-method immutability and was re-executed successfully with error 1644 ('Payment evidence is immutable'). The full 72-test regression suite should be rerun before final submission if the report continues to claim all 72 checks passed. Existing RBAC/query evidence remains valid only where it does not depend on removed PAYMENT columns.

## Remaining assessment risk

PAYMENT now uses the normalized attempt structure and no longer stores payer_id, payee_id or amount. Under the stated business FDs, all 11 business relations satisfy 3NF/BCNF; paid_milestone_id remains only a generated implementation helper for conditional uniqueness. The remaining assessment risk is regression evidence: the full integrity/workflow/concurrency suite should be rerun after the schema change before retaining the blanket '72 checks passed' claim. Encryption at rest and restore-drill targets are requirements, not demonstrated deployments. Semester Phase 4 UI, defense and peer evaluation remain out of this task scope.
