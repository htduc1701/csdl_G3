# Functional dependencies and normalization

Assumptions: email, skill_name and category_name are unique under utf8mb4_0900_ai_ci collation. Phone, company name and professional title are not unique. Skill level belongs to the freelancer-skill pair, not to either identifier alone. Proposed amounts need not equal job budgets. A proposal identifies its original agreement, and contract.proposal_id is UNIQUE NOT NULL. No hidden dependency such as freelancer_id -> proposed_amount is assumed.

Every business column holds a single value. Keys distinguish tuples, and skills are represented by an associative relation:1NF. All determinants listed as candidate keys are minimal. The only composite candidate key with a non-key business attribute is freelancer_skills(freelancer_id,skill_id); neither component determines skill_level. Proposal's alternate composite key is minimal and no component determines its non-key business attributes. There is therefore no assumed partial dependency:2NF.

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
| proposals | proposal_id; (job_id, freelancer_id) | proposal_id -> all; (job_id, freelancer_id) -> all; (job_id,status) -> selected_job_id | BCNF on business columns; generated attribute is technical |
| contracts | contract_id; proposal_id | contract_id -> all; proposal_id -> all | BCNF |
| milestones | milestone_id | milestone_id -> all other milestone columns | BCNF |
| payments | payment_id | payment_id -> all; milestone_id -> amount,payer_id,payee_id; (milestone_id,payment_status) -> paid_milestone_id | 2NF; not3NF/BCNF |

For the ten business relations marked BCNF, every listed determinant is a candidate key and its closure includes all attributes; no additional dependency is assumed. CONTRACT stores redundant cross-table participant references, but proposal_id is its own candidate key, so this redundancy alone is not a within-relation3NF violation.

PAYMENT allows multiple attempts. Two attempts for one milestone have the same amount/payer/payee but different payment_id and possibly different method/status. Therefore milestone_id is not a superkey. amount, payer_id and payee_id are non-prime attributes and milestone_id -> these attributes violates3NF and BCNF. This is a controlled financial-evidence denormalization, enforced with triggers and immutable work terms. The full physical schema, including generated columns, is not claimed strictly BCNF.

Normalized alternative preserving11 entities: use payments(payment_id PK,milestone_id FK,payment_method,payment_status,paid_milestone_id generated), project away amount,payer_id,payee_id, and expose them through a JOIN view over milestone, contract and users. At the business-relation level only payment_id -> all remains, satisfying BCNF under these FDs. Existing data decomposes losslessly because milestone_id joins a single milestone and each contract identifies one pair of participants; sum limits and historical immutability remain cross-relation rules. This alternative changes the explicit PAYMENT fields used in BR-16, and would need the instructor/team to accept derived transfer evidence. It was not silently applied.
