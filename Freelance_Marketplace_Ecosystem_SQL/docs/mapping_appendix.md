# Mapping appendix

Entity labels USER, CLIENT, FREELANCER, SKILL, FREELANCER_SKILL, JOB_CATEGORY, JOB, PROPOSAL, CONTRACT, MILESTONE and PAYMENT map in that order to users, clients, freelancers, skills, freelancer_skills, job_categories, jobs, proposals, contracts, milestones, payments. All11 retained.

Each subtype row participates totally in its user FK; each user has0..1 row of either particular subtype, with exactly1 across their disjoint union. Total/disjoint is a semantic condition in addition to the two individual Crow Foot links.

Parents in all other1:N relations may have zero children. Each child has exactly1 parent due to NOT NULL FK. A proposal has0..1 contract, and each contract exactly1 proposal. Milestone has0..N payment attempts, with0..1 PAID result; failed/pending attempts do not count as success. A fresh active contract can initially have zero milestones; completion requires full paid allocation.

The physical diagrams split account/catalog and execution domains for readability. The same account references are represented by duplicate labeled boundary boxes in the rendered figures; they do not create additional entities. Keys, FKs and attribute details are authoritative in dictionary and01_schema.sql.

Technical additions: users.user_type restored to mapping; jobs.created_at for deterministic dates; proposals.selected_job_id and payments.paid_milestone_id are generated uniqueness helpers. No business entity added. Payment method labels normalize the original textual examples to PAYPAL, CREDIT_CARD and BANK_TRANSFER. Profile title is initialized to Not specified atomically and can be edited.
