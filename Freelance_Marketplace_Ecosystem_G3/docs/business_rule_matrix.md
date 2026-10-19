# Business rule coverage

| BR | Enforcement |
|---|---|
| BR-01 | users PK |
| BR-02 | Auto subtype creation/type and retention triggers; discriminator CHECK |
| BR-03 | jobs.client_id NOT NULL FK |
| BR-04 | jobs.category_id NOT NULL FK |
| BR-05 | Composite freelancer_skills PK/FKs |
| BR-06 | proposals.job_id FK |
| BR-07 | proposals.freelancer_id FK |
| BR-08 | UNIQUE(job_id,freelancer_id) |
| BR-09 | NOT NULL FKs to job/freelancer |
| BR-10 | UNIQUE generated selected_job_id |
| BR-11 | PENDING->CLIENT_ACCEPTED->CONFIRMED; AFTER UPDATE creates one UNIQUE contract atomically; retain contract |
| BR-12 | Contract participant guard, immutable references; role-owned procedures |
| BR-13 | milestones.contract_id NOT NULL FK |
| BR-14 | amount CHECK; parent lock and current aggregate under supported READ COMMITTED; contract update guard |
| BR-15 | Ordered completion then approval; payment requires APPROVED; native account ownership checks |
| BR-16 | Exact payer/payee/amount trigger and method CHECK; one PAID generated UNIQUE |
