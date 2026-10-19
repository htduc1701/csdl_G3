# Expanded dataset execution report

Engine: 8.0.42. Isolation: READ-COMMITTED.

Actual total rows: **7223**. All expected table counts matched.

| Table | Actual rows |
|---|---:|
| users | 248 |
| clients | 43 |
| freelancers | 205 |
| skills | 26 |
| freelancer_skills | 610 |
| job_categories | 11 |
| jobs | 1008 |
| proposals | 1811 |
| contracts | 605 |
| milestones | 1810 |
| payments | 846 |

## Integrity verification

All nine invariant queries returned zero violations. No FK, CHECK, UNIQUE or trigger was disabled.
- subtype_violation: 0
- duplicate_proposal_pair: 0
- multiple_selected: 0
- missing_confirmed_contract: 0
- bad_contract_parties: 0
- milestone_overflow: 0
- bad_payment: 0
- multiple_paid: 0
- milestone_dates: 0

## Actual workflow states

jobs: COMPLETED=120, IN_PROGRESS=485, OPEN=403

proposals: CLIENT_ACCEPTED=101, CONFIRMED=605, PENDING=505, REJECTED=600

contracts: ACTIVE=485, COMPLETED=120

milestones: APPROVED=725, COMPLETED=241, IN_PROGRESS=120, PENDING=724

payments: FAILED=242, PAID=483, PENDING=121

## Advanced query results

These results replace the small-seed expected/actual outputs when demonstrating the expanded fixture. Tables below show at most the first ten returned rows; full row counts are provided. Executable SQL is in sql/06_queries.sql.

### Q-01

Actual rows returned: 1008. Execution succeeded.

```sql
SELECT *
FROM v_job_proposals
ORDER BY job_id;
```

| job_id | client_id | title | status | budget_max | proposal_count | selected_count |
|---|---|---|---|---|---|---|
| 1 | 1 | Demo job 1 | IN_PROGRESS | 1000.00 | 2 | 1 |
| 2 | 1 | Demo job 2 | IN_PROGRESS | 800.00 | 2 | 1 |
| 3 | 2 | Demo job 3 | IN_PROGRESS | 1500.00 | 2 | 1 |
| 4 | 2 | Demo job 4 | IN_PROGRESS | 600.00 | 1 | 1 |
| 5 | 3 | Demo job 5 | IN_PROGRESS | 2000.00 | 2 | 1 |
| 6 | 3 | Demo job 6 | OPEN | 900.00 | 1 | 1 |
| 7 | 1 | Demo job 7 | OPEN | 500.00 | 0 | 0 |
| 8 | 2 | Demo job 8 | OPEN | 1200.00 | 1 | 0 |
| 22001 | 20001 | Company website project 1 | IN_PROGRESS | 930.00 | 2 | 1 |
| 22002 | 20002 | Mobile booking app project 2 | IN_PROGRESS | 960.00 | 2 | 1 |

### Q-02

Actual rows returned: 204. Execution succeeded.

```sql
SELECT freelancer_id,
       COUNT(*) AS proposals
FROM proposals
GROUP BY freelancer_id
HAVING COUNT(*) >= 2
ORDER BY freelancer_id;
```

| freelancer_id | proposals |
|---|---|
| 4 | 3 |
| 6 | 3 |
| 7 | 2 |
| 8 | 2 |
| 21001 | 9 |
| 21002 | 9 |
| 21003 | 9 |
| 21004 | 9 |
| 21005 | 9 |
| 21006 | 9 |

### Q-03

Actual rows returned: 101. Execution succeeded.

```sql
SELECT j.job_id,
       j.title
FROM jobs AS j
WHERE NOT EXISTS
        (SELECT 1
         FROM proposals AS p
         WHERE p.job_id = j.job_id)
ORDER BY j.job_id;
```

| job_id | title |
|---|---|
| 7 | Demo job 7 |
| 22901 | Product interface project 901 |
| 22902 | Regression test suite project 902 |
| 22903 | Cloud deployment project 903 |
| 22904 | Technical documentation project 904 |
| 22905 | Company website project 905 |
| 22906 | Mobile booking app project 906 |
| 22907 | Data pipeline project 907 |
| 22908 | Sales dashboard project 908 |
| 22909 | Product interface project 909 |

### Q-04

Actual rows returned: 204. Execution succeeded.

```sql
WITH totals AS
    (SELECT freelancer_id,
            SUM(total_amount) AS value
     FROM contracts
     WHERE status <> 'CANCELLED'
     GROUP BY freelancer_id)
SELECT freelancer_id,
       value,
       DENSE_RANK() OVER (
                          ORDER BY value DESC) AS value_rank
FROM totals
ORDER BY value_rank,
         freelancer_id;
```

| freelancer_id | value | value_rank |
|---|---|---|
| 21039 | 6210.00 | 1 |
| 21079 | 6210.00 | 1 |
| 21119 | 6210.00 | 1 |
| 21159 | 6210.00 | 1 |
| 21199 | 6210.00 | 1 |
| 21038 | 6120.00 | 2 |
| 21078 | 6120.00 | 2 |
| 21118 | 6120.00 | 2 |
| 21158 | 6120.00 | 2 |
| 21198 | 6120.00 | 2 |

### Q-05

Actual rows returned: 43. Execution succeeded.

```sql
SELECT *
FROM v_client_spend
ORDER BY client_id;
```

| client_id | paid_count | paid_amount |
|---|---|---|
| 1 | 2 | 700.00 |
| 2 | 1 | 200.00 |
| 3 | 0 | 0.00 |
| 20001 | 15 | 4650.00 |
| 20002 | 0 | 0.00 |
| 20003 | 0 | 0.00 |
| 20004 | 0 | 0.00 |
| 20005 | 45 | 15750.00 |
| 20006 | 15 | 5400.00 |
| 20007 | 0 | 0.00 |

### Q-06

Actual rows returned: 485. Execution succeeded.

```sql
SELECT contract_id,
       total_amount,
       paid_amount,
       outstanding_amount
FROM v_contract_overview
WHERE outstanding_amount > 0
ORDER BY contract_id;
```

| contract_id | total_amount | paid_amount | outstanding_amount |
|---|---|---|---|
| 1 | 1000.00 | 400.00 | 600.00 |
| 2 | 800.00 | 300.00 | 500.00 |
| 3 | 1500.00 | 0.00 | 1500.00 |
| 4 | 600.00 | 200.00 | 400.00 |
| 5 | 2000.00 | 0.00 | 2000.00 |
| 6 | 930.00 | 310.00 | 620.00 |
| 7 | 960.00 | 0.00 | 960.00 |
| 8 | 990.00 | 0.00 | 990.00 |
| 9 | 1020.00 | 0.00 | 1020.00 |
| 11 | 1080.00 | 360.00 | 720.00 |

### Q-07

Actual rows returned: 483. Execution succeeded.

```sql
SELECT m.milestone_id,
       m.status,
       m.amount
FROM milestones AS m
WHERE m.status IN ('COMPLETED',
                   'APPROVED')
    AND NOT EXISTS
        (SELECT 1
         FROM payments AS p
         WHERE p.milestone_id=m.milestone_id
             AND p.payment_status='PAID')
ORDER BY m.milestone_id;
```

| milestone_id | status | amount |
|---|---|---|
| 2 | COMPLETED | 600.00 |
| 5 | APPROVED | 500.00 |
| 9 | APPROVED | 500.00 |
| 26002 | COMPLETED | 310.00 |
| 26004 | APPROVED | 320.00 |
| 26007 | APPROVED | 330.00 |
| 26010 | COMPLETED | 340.00 |
| 26017 | COMPLETED | 360.00 |
| 26019 | APPROVED | 370.00 |
| 26022 | APPROVED | 380.00 |

### Q-08

Actual rows returned: 502. Execution succeeded.

```sql
SELECT job_id,
       budget_max
FROM jobs
WHERE budget_max >
        (SELECT AVG(budget_max)
         FROM jobs)
ORDER BY job_id;
```

| job_id | budget_max |
|---|---|
| 3 | 1500.00 |
| 5 | 2000.00 |
| 22020 | 1500.00 |
| 22021 | 1530.00 |
| 22022 | 1560.00 |
| 22023 | 1590.00 |
| 22024 | 1620.00 |
| 22025 | 1650.00 |
| 22026 | 1680.00 |
| 22027 | 1710.00 |

### Q-09

Actual rows returned: 202. Execution succeeded.

```sql
SELECT f.freelancer_id,
       f.professional_title,
       COUNT(fs.skill_id) AS skill_count
FROM freelancers AS f
INNER JOIN freelancer_skills AS fs ON fs.freelancer_id=f.freelancer_id
GROUP BY f.freelancer_id,
         f.professional_title
HAVING COUNT(fs.skill_id)>=3
ORDER BY f.freelancer_id;
```

| freelancer_id | professional_title | skill_count |
|---|---|---|
| 4 | Database and software specialist | 3 |
| 6 | Database and software specialist | 3 |
| 21001 | Data Engineer | 3 |
| 21002 | Product Designer | 3 |
| 21003 | QA Engineer | 3 |
| 21004 | Web Developer | 3 |
| 21005 | Data Engineer | 3 |
| 21006 | Product Designer | 3 |
| 21007 | QA Engineer | 3 |
| 21008 | Web Developer | 3 |

### Q-10

Actual rows returned: 605. Execution succeeded.

```sql
SELECT *
FROM v_contract_overview
ORDER BY contract_id;
```

| contract_id | client_id | freelancer_id | total_amount | status | milestone_count | allocated_amount | paid_amount | outstanding_amount |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 4 | 1000.00 | ACTIVE | 2 | 1000.00 | 400.00 | 600.00 |
| 2 | 1 | 5 | 800.00 | ACTIVE | 2 | 800.00 | 300.00 | 500.00 |
| 3 | 2 | 6 | 1500.00 | ACTIVE | 2 | 1500.00 | 0.00 | 1500.00 |
| 4 | 2 | 7 | 600.00 | ACTIVE | 2 | 600.00 | 200.00 | 400.00 |
| 5 | 3 | 4 | 2000.00 | ACTIVE | 2 | 2000.00 | 0.00 | 2000.00 |
| 6 | 20001 | 21001 | 930.00 | ACTIVE | 3 | 930.00 | 310.00 | 620.00 |
| 7 | 20002 | 21002 | 960.00 | ACTIVE | 3 | 960.00 | 0.00 | 960.00 |
| 8 | 20003 | 21003 | 990.00 | ACTIVE | 3 | 990.00 | 0.00 | 990.00 |
| 9 | 20004 | 21004 | 1020.00 | ACTIVE | 3 | 1020.00 | 0.00 | 1020.00 |
| 10 | 20005 | 21005 | 1050.00 | COMPLETED | 3 | 1050.00 | 1050.00 | 0.00 |

### Q-11

Actual rows returned: 40. Execution succeeded.

```sql
WITH counts AS
    (SELECT client_id,
            COUNT(*) AS job_count
     FROM jobs
     GROUP BY client_id),
     ranked AS
    (SELECT *,
            DENSE_RANK() OVER (
                               ORDER BY job_count DESC) AS r
     FROM counts)
SELECT client_id,
       job_count
FROM ranked
WHERE r=1
ORDER BY client_id;
```

| client_id | job_count |
|---|---|
| 20001 | 25 |
| 20002 | 25 |
| 20003 | 25 |
| 20004 | 25 |
| 20005 | 25 |
| 20006 | 25 |
| 20007 | 25 |
| 20008 | 25 |
| 20009 | 25 |
| 20010 | 25 |

### Q-12

Actual rows returned: 125. Execution succeeded.

```sql
SELECT c.contract_id,
       COUNT(m.milestone_id) AS overdue_work
FROM contracts AS c
JOIN milestones AS m ON m.contract_id=c.contract_id
WHERE c.status='ACTIVE'
    AND m.status IN ('PENDING',
                     'IN_PROGRESS',
                     'COMPLETED')
    AND m.due_date < DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY c.contract_id
ORDER BY c.contract_id;
```

| contract_id | overdue_work |
|---|---|
| 1 | 1 |
| 2 | 1 |
| 3 | 1 |
| 4 | 1 |
| 5 | 1 |
| 9 | 1 |
| 14 | 1 |
| 19 | 1 |
| 24 | 1 |
| 29 | 1 |
