# Functional dependencies and normalization

Assumptions: email, skill_name and category_name are unique under utf8mb4_0900_ai_ci collation. Phone, company name and professional title are not unique. Skill level belongs to the freelancer-skill pair, not to either identifier alone. Proposed amounts need not equal job budgets. A proposal identifies its original agreement, and contract.proposal_id is UNIQUE NOT NULL. No hidden dependency such as freelancer_id -> proposed_amount is assumed.

Each business column holds a single value, and freelancer skills use a separate associative relation (1NF). The composite candidate keys are `freelancer_skills(freelancer_id, skill_id)` and `proposals(job_id, freelancer_id)`. Neither component of either key determines a non-prime attribute on its own under the stated business dependencies (2NF).

For BCNF each nontrivial FD determinant must be a superkey. Expanding the stated covers to one RHS attribute gives the following verification. PK-only assertions alone are insufficient. Generated helper columns are projections of existing values, not independent business facts; including them creates extra computed-column FDs, so the BCNF claim is explicitly about the business relations with those technical helpers projected away.

| Relation | Candidate keys | FD cover | Result |
|---|---|---|---|
| users | user_id; email | user_id -> all; email -> all | BCNF |
| clients | client_id | client_id -> company_name, company_description, location | BCNF |
| freelancers | freelancer_id | freelancer_id -> professional_title, bio, hourly_rate, experience_level | BCNF |
| skills | skill_id; skill_name | skill_id -> skill_name; skill_name -> skill_id | BCNF |
| freelancer_skills | (freelancer_id, skill_id) | (freelancer_id, skill_id) -> skill_level | BCNF |
| job_categories | category_id; category_name | category_id -> all; category_name -> all | BCNF |
| jobs | job_id | job_id -> all other job columns | BCNF |
| proposals | proposal_id; (job_id, freelancer_id) | proposal_id -> all business columns; (job_id, freelancer_id) -> all business columns | BCNF |
| contracts | contract_id; proposal_id | contract_id -> all; proposal_id -> all | BCNF |
| milestones | milestone_id | milestone_id -> all other milestone columns | BCNF |
| payments | payment_id | payment_id -> milestone_id, payment_method, payment_status | BCNF |

For all 11 logical business relations, every determinant in the table is a candidate key. These relations therefore satisfy BCNF and 3NF under the stated dependencies. Within CONTRACT, `proposal_id` is a candidate key because it is `UNIQUE NOT NULL`. It determines the stored participant references.

The physical schema also has `(job_id, status) -> selected_job_id` and `(milestone_id, payment_status) -> paid_milestone_id`. These determinants may repeat across pending proposals or failed payment attempts. The BCNF conclusion applies to the logical relations after projecting out the two generated columns.

PAYMENT allows multiple attempts for one milestone, and each attempt stores only its own method and status with the milestone reference. Payer, payee and amount are derived through the milestone and contract, so they are not duplicated in PAYMENT. At the business-relation level payment_id is the only determinant; the generated paid_milestone_id helper is excluded from the FD proof because it is computed from milestone_id and payment_status. This matches the normalized PAYMENT definition in sql/01_schema.sql.
