# Executed data dictionary

## users

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| user_id | int | PK | NO | Identity | Account identifier |
| email | varchar(150) | UQ | NO | None | Unique account email |
| full_name | varchar(100) | — | NO | None | Display name |
| password_hash | varchar(255) | — | NO | None | Credential hash; fixture values cannot log in |
| phone | varchar(20) | — | YES | NULL | Optional contact number |
| user_type | varchar(20) | — | NO | None | CLIENT or FREELANCER; immutable |

## clients

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| client_id | int | FK, PK | NO | None | Hiring account identifier; References users.user_id |
| company_name | varchar(150) | — | YES | NULL | Optional company display name |
| company_description | text | — | YES | NULL | Optional company description |
| location | varchar(150) | — | YES | NULL | Optional profile location |

## freelancers

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| freelancer_id | int | FK, PK | NO | None | Freelancer account identifier; References users.user_id |
| professional_title | varchar(150) | — | NO | Not specified | Professional profile title |
| bio | text | — | YES | NULL | Optional profile biography |
| hourly_rate | decimal(10,2) | — | NO | 0.00 | Nonnegative advertised USD rate |
| experience_level | varchar(20) | — | NO | INTERMEDIATE | BEGINNER, INTERMEDIATE, ADVANCED or EXPERT |

## skills

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| skill_id | int | PK | NO | Identity | Skill identifier |
| skill_name | varchar(100) | UQ | NO | None | Unique skill name |

## freelancer_skills

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| freelancer_id | int | FK, PK | NO | None | Freelancer account identifier; References freelancers.freelancer_id |
| skill_id | int | FK, PK | NO | None | Skill identifier; References skills.skill_id |
| skill_level | varchar(20) | — | NO | INTERMEDIATE | Proficiency of this freelancer in this skill |

## job_categories

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| category_id | int | PK | NO | Identity | Job category identifier |
| category_name | varchar(100) | UQ | NO | None | Unique category name |
| description | text | — | YES | NULL | Business description |

## jobs

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| job_id | int | PK | NO | Identity | Job identifier |
| client_id | int | FK | NO | None | Hiring account identifier; References clients.client_id |
| category_id | int | FK | NO | None | Job category identifier; References job_categories.category_id |
| title | varchar(200) | — | NO | None | Job or milestone title |
| description | text | — | NO | None | Business description |
| budget_min | decimal(15,2) | — | NO | 0.00 | Nonnegative lower budget |
| budget_max | decimal(15,2) | — | NO | 0.00 | Upper budget at least budget_min |
| deadline | date | — | YES | NULL | Optional date later than DATE(created_at) |
| status | varchar(20) | — | NO | OPEN | Constrained workflow state |
| created_at | datetime | — | NO | Current timestamp | Creation timestamp |

## proposals

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| proposal_id | int | PK | NO | Identity | Offer identifier |
| job_id | int | FK, UQ | NO | None | Job identifier; References jobs.job_id |
| freelancer_id | int | FK, UQ | NO | None | Freelancer account identifier; References freelancers.freelancer_id |
| proposed_amount | decimal(15,2) | — | NO | None | Strictly positive quoted USD amount |
| cover_letter | text | — | NO | None | Proposal narrative |
| estimated_days | int | — | NO | None | Strictly positive delivery duration |
| status | varchar(20) | — | NO | PENDING | Constrained workflow state |
| submitted_at | datetime | — | NO | Current timestamp | Offer submission timestamp |

## contracts

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| contract_id | int | PK | NO | Identity | Contract identifier |
| proposal_id | int | FK, UQ | NO | None | Offer identifier; References proposals.proposal_id |
| client_id | int | FK | NO | None | Hiring account identifier; References clients.client_id |
| freelancer_id | int | FK | NO | None | Freelancer account identifier; References freelancers.freelancer_id |
| start_date | date | — | NO | None | Fixed agreement start date |
| end_date | date | — | YES | NULL | Optional end after start; contains milestone dates |
| total_amount | decimal(15,2) | — | NO | None | Fixed positive agreement amount |
| status | varchar(20) | — | NO | ACTIVE | Constrained workflow state |

## milestones

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| milestone_id | int | PK | NO | Identity | Delivery milestone identifier |
| contract_id | int | FK | NO | None | Contract identifier; References contracts.contract_id |
| title | varchar(200) | — | NO | None | Job or milestone title |
| description | text | — | YES | NULL | Business description |
| amount | decimal(15,2) | — | NO | None | Positive USD milestone amount; parent budget guard |
| due_date | date | — | YES | NULL | Optional deadline within contract dates |
| status | varchar(20) | — | NO | PENDING | Constrained workflow state |

## payments

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| payment_id | int | PK | NO | Identity | Payment attempt identifier |
| milestone_id | int | FK | NO | None | Delivery milestone identifier; References milestones.milestone_id |
| payment_status | varchar(20) | — | NO | PENDING | PENDING, PAID or FAILED |
| payment_method | varchar(50) | — | NO | None | PAYPAL, CREDIT_CARD or BANK_TRANSFER |

## contract_reviews

| Attribute | Type | Key | Null | Default | Meaning and rules |
|---|---|---|---|---|---|
| contract_id | int | FK, PK | NO | None | Contract identifier; References contracts.contract_id |
| rating | tinyint | — | NO | None | Integer 1 to 5; client review of completed contract |
| review_text | varchar(1000) | — | YES | NULL | Optional review comment |
| created_at | datetime | — | NO | Current timestamp | Creation timestamp |
