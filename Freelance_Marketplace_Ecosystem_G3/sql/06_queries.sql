USE mini_upwork;

-- Q-01 Jobs and proposal counts
SELECT *
FROM v_job_proposals
ORDER BY job_id;

-- Q-02 Freelancers with at least two proposals
SELECT freelancer_id,
       COUNT(*) AS proposals
FROM proposals
GROUP BY freelancer_id
HAVING COUNT(*) >= 2
ORDER BY freelancer_id;

-- Q-03 Jobs with no proposals
SELECT j.job_id,
       j.title
FROM jobs AS j
WHERE NOT EXISTS
        (SELECT 1
         FROM proposals AS p
         WHERE p.job_id = j.job_id)
ORDER BY j.job_id;

-- Q-04 Rank freelancer contract value
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

-- Q-05 Client successful payment totals
SELECT *
FROM v_client_spend
ORDER BY client_id;

-- Q-06 Contracts not fully paid
SELECT contract_id,
       total_amount,
       paid_amount,
       outstanding_amount
FROM v_contract_overview
WHERE outstanding_amount > 0
ORDER BY contract_id;

-- Q-07 Completed work not yet paid
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

-- Q-08 Jobs above mean maximum budget
SELECT job_id,
       budget_max
FROM jobs
WHERE budget_max >
        (SELECT AVG(budget_max)
         FROM jobs)
ORDER BY job_id;

-- Q-09 Freelancers with at least three skills
SELECT f.freelancer_id,
       f.professional_title,
       COUNT(fs.skill_id) AS skill_count
FROM freelancers AS f
INNER JOIN freelancer_skills AS fs ON fs.freelancer_id=f.freelancer_id
GROUP BY f.freelancer_id,
         f.professional_title
HAVING COUNT(fs.skill_id)>=3
ORDER BY f.freelancer_id;

-- Q-10 Contract milestone payment report
SELECT *
FROM v_contract_overview
ORDER BY contract_id;

-- Q-11 Clients posting the most jobs
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

-- Q-12 Contracts at risk by a supplied reference date
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
