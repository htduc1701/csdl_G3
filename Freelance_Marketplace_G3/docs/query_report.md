# Advanced queries and actual performance

Seed state:8 users,3 clients,5 freelancers,6 skills,10 freelancer-skill links,3 categories,8 jobs,11 proposals,5 contracts,10 milestones and6 payment attempts. All12 expected output assertions passed. Time is client-observed latency including fetch;1 warmup plus10 measured executions. Small-data timing is not a scalability claim.

## Q-01 Jobs and proposal counts

Expected: 8 jobs, counts 2,2,2,1,2,1,0,1

```sql
SELECT *
FROM v_job_proposals
ORDER BY job_id;
```

Actual:
```json
[
  [
    1,
    1,
    "Demo job 1",
    "IN_PROGRESS",
    "1000.00",
    2,
    "1"
  ],
  [
    2,
    1,
    "Demo job 2",
    "IN_PROGRESS",
    "800.00",
    2,
    "1"
  ],
  [
    3,
    2,
    "Demo job 3",
    "IN_PROGRESS",
    "1500.00",
    2,
    "1"
  ],
  [
    4,
    2,
    "Demo job 4",
    "IN_PROGRESS",
    "600.00",
    1,
    "1"
  ],
  [
    5,
    3,
    "Demo job 5",
    "IN_PROGRESS",
    "2000.00",
    2,
    "1"
  ],
  [
    6,
    3,
    "Demo job 6",
    "OPEN",
    "900.00",
    1,
    "1"
  ],
  [
    7,
    1,
    "Demo job 7",
    "OPEN",
    "500.00",
    0,
    "0"
  ],
  [
    8,
    2,
    "Demo job 8",
    "OPEN",
    "1200.00",
    1,
    "0"
  ]
]
```

LEFT JOIN retains jobs with no proposals.

Median latency: 0.399 ms.

EXPLAIN ANALYZE:
```text
-> Sort: v_job_proposals.job_id  (cost=2.6..2.6 rows=0) (actual time=0.0727..0.0733 rows=8 loops=1)
    -> Table scan on v_job_proposals  (cost=2.5..2.5 rows=0) (actual time=0.0662..0.0671 rows=8 loops=1)
        -> Materialize  (cost=0..0 rows=0) (actual time=0.0658..0.0658 rows=8 loops=1)
            -> Table scan on <temporary>  (actual time=0.0569..0.0579 rows=8 loops=1)
                -> Aggregate using temporary table  (actual time=0.0564..0.0564 rows=8 loops=1)
                    -> Nested loop left join  (cost=5.45 rows=12.6) (actual time=0.0185..0.0362 rows=12 loops=1)
                        -> Table scan on j  (cost=1.05 rows=8) (actual time=0.0101..0.0126 rows=8 loops=1)
                        -> Index lookup on p using uq_proposal_freelancer_job (job_id=j.job_id)  (cost=0.412 rows=1.57) (actual time=0.00225..0.00264 rows=1.38 loops=8)

```

## Q-02 Freelancers with at least two proposals

Expected: IDs 4:3, 6:3, 7:2, 8:2

```sql
SELECT freelancer_id,
       COUNT(*) AS proposals
FROM proposals
GROUP BY freelancer_id
HAVING COUNT(*) >= 2
ORDER BY freelancer_id;
```

Actual:
```json
[
  [
    4,
    3
  ],
  [
    6,
    3
  ],
  [
    7,
    2
  ],
  [
    8,
    2
  ]
]
```

HAVING filters aggregate groups.

Median latency: 0.105 ms.

EXPLAIN ANALYZE:
```text
-> Filter: (count(0) >= 2)  (cost=2.45 rows=5) (actual time=0.00627..0.00857 rows=4 loops=1)
    -> Group aggregate: count(0), count(0)  (cost=2.45 rows=5) (actual time=0.00553..0.00742 rows=5 loops=1)
        -> Covering index scan on proposals using fk_proposals_freelancer  (cost=1.35 rows=11) (actual time=0.00401..0.00546 rows=11 loops=1)

```

## Q-03 Jobs with no proposals

Expected: Job 7

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

Actual:
```json
[
  [
    7,
    "Demo job 7"
  ]
]
```

Correlated anti-existence test.

Median latency: 0.106 ms.

EXPLAIN ANALYZE:
```text
-> Nested loop antijoin  (cost=4.31 rows=12.6) (actual time=0.0132..0.0154 rows=1 loops=1)
    -> Index scan on j using PRIMARY  (cost=1.05 rows=8) (actual time=0.00449..0.00662 rows=8 loops=1)
    -> Covering index lookup on p using uq_proposal_freelancer_job (job_id=j.job_id)  (cost=0.424 rows=1.57) (actual time=939e-6..939e-6 rows=0.875 loops=8)

```

## Q-04 Rank freelancer contract value

Expected: 4:3000 rank1; 6:1500 rank2; 5:800 rank3; 7:600 rank4

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

Actual:
```json
[
  [
    4,
    "3000.00",
    1
  ],
  [
    6,
    "1500.00",
    2
  ],
  [
    5,
    "800.00",
    3
  ],
  [
    7,
    "600.00",
    4
  ]
]
```

CTE and window ranking.

Median latency: 0.224 ms.

EXPLAIN ANALYZE:
```text
-> Sort: value_rank, totals.freelancer_id  (actual time=0.0375..0.0377 rows=4 loops=1)
    -> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=0.0353..0.0356 rows=4 loops=1)
        -> Temporary table  (cost=0..0 rows=0) (actual time=0.035..0.035 rows=4 loops=1)
            -> Window aggregate: dense_rank() OVER (ORDER BY totals.`value` desc )   (actual time=0.0301..0.0312 rows=4 loops=1)
                -> Sort: totals.`value` DESC  (cost=4.28..4.28 rows=2) (actual time=0.0286..0.0289 rows=4 loops=1)
                    -> Table scan on totals  (cost=2.61..3.88 rows=2) (actual time=0.0241..0.0246 rows=4 loops=1)
                        -> Materialize CTE totals  (cost=1.35..1.35 rows=2) (actual time=0.0235..0.0235 rows=4 loops=1)
                            -> Group aggregate: sum(contracts.total_amount)  (cost=1.15 rows=2) (actual time=0.0182..0.0199 rows=4 loops=1)
                                -> Filter: (contracts.`status` <> 'CANCELLED')  (cost=0.75 rows=4) (actual time=0.0153..0.0171 rows=5 loops=1)
                                    -> Index scan on contracts using fk_contract_freelancer  (cost=0.75 rows=5) (actual time=0.0144..0.0157 rows=5 loops=1)

```

## Q-05 Client successful payment totals

Expected: Client1 700; client2 200; client3 0

```sql
SELECT *
FROM v_client_spend
ORDER BY client_id;
```

Actual:
```json
[
  [
    1,
    2,
    "700.00"
  ],
  [
    2,
    1,
    "200.00"
  ],
  [
    3,
    0,
    "0.00"
  ]
]
```

Only PAID attempts contribute.

Median latency: 0.300 ms.

EXPLAIN ANALYZE:
```text
-> Sort: v_client_spend.client_id  (cost=2.6..2.6 rows=0) (actual time=0.0396..0.0397 rows=3 loops=1)
    -> Table scan on v_client_spend  (cost=2.5..2.5 rows=0) (actual time=0.0352..0.0355 rows=3 loops=1)
        -> Materialize  (cost=0..0 rows=0) (actual time=0.0349..0.0349 rows=3 loops=1)
            -> Table scan on <temporary>  (actual time=0.0299..0.0303 rows=3 loops=1)
                -> Aggregate using temporary table  (actual time=0.0295..0.0295 rows=3 loops=1)
                    -> Left hash join (p.payer_id = c.client_id)  (cost=2.33 rows=18) (actual time=0.0207..0.0225 rows=4 loops=1)
                        -> Covering index scan on c using PRIMARY  (cost=0.55 rows=3) (actual time=0.00198..0.00276 rows=3 loops=1)
                        -> Hash
                            -> Filter: (p.payment_status = 'PAID')  (cost=0.283 rows=6) (actual time=0.0108..0.0126 rows=3 loops=1)
                                -> Table scan on p  (cost=0.283 rows=6) (actual time=0.00934..0.0112 rows=6 loops=1)

```

## Q-06 Contracts not fully paid

Expected: Outstanding 600,500,1500,400,2000

```sql
SELECT contract_id,
       total_amount,
       paid_amount,
       outstanding_amount
FROM v_contract_overview
WHERE outstanding_amount > 0
ORDER BY contract_id;
```

Actual:
```json
[
  [
    1,
    "1000.00",
    "400.00",
    "600.00"
  ],
  [
    2,
    "800.00",
    "300.00",
    "500.00"
  ],
  [
    3,
    "1500.00",
    "0.00",
    "1500.00"
  ],
  [
    4,
    "600.00",
    "200.00",
    "400.00"
  ],
  [
    5,
    "2000.00",
    "0.00",
    "2000.00"
  ]
]
```

Pre-aggregation prevents payment retry fan-out.

Median latency: 0.484 ms.

EXPLAIN ANALYZE:
```text
-> Sort: v_contract_overview.contract_id  (actual time=0.0775..0.0778 rows=5 loops=1)
    -> Stream results  (cost=5.03 rows=0) (actual time=0.0644..0.0722 rows=5 loops=1)
        -> Filter: ((c.total_amount - coalesce(p.paid_amount,0)) > 0)  (cost=5.03 rows=0) (actual time=0.063..0.0692 rows=5 loops=1)
            -> Left hash join (p.contract_id = c.contract_id)  (cost=5.03 rows=0) (actual time=0.0612..0.0664 rows=5 loops=1)
                -> Nested loop left join  (cost=4.83 rows=15.8) (actual time=0.0223..0.0263 rows=5 loops=1)
                    -> Table scan on c  (cost=0.75 rows=5) (actual time=0.00256..0.00351 rows=5 loops=1)
                    -> Index lookup on m using <auto_key0> (contract_id=c.contract_id)  (cost=2.84..3.11 rows=2) (actual time=0.00415..0.00436 rows=1 loops=5)
                        -> Materialize  (cost=2.57..2.57 rows=3.16) (actual time=0.0186..0.0186 rows=5 loops=1)
                            -> Group aggregate: count(0), sum(milestones.amount)  (cost=2.25 rows=3.16) (actual time=0.00949..0.0145 rows=5 loops=1)
                                -> Index scan on milestones using fk_milestone_contract  (cost=1.25 rows=10) (actual time=0.00665..0.0108 rows=10 loops=1)
                -> Hash
                    -> Table scan on p  (cost=2.5..2.5 rows=0) (actual time=0.0325..0.0328 rows=3 loops=1)
                        -> Materialize  (cost=0..0 rows=0) (actual time=0.0322..0.0322 rows=3 loops=1)
                            -> Table scan on <temporary>  (actual time=0.0273..0.0276 rows=3 loops=1)
                                -> Aggregate using temporary table  (actual time=0.0268..0.0268 rows=3 loops=1)
                                    -> Nested loop inner join  (cost=1.2 rows=1) (actual time=0.0169..0.0215 rows=3 loops=1)
                                        -> Filter: (p.payment_status = 'PAID')  (cost=0.85 rows=1) (actual time=0.0124..0.015 rows=3 loops=1)
                                            -> Table scan on p  (cost=0.85 rows=6) (actual time=0.0108..0.0133 rows=6 loops=1)
                                        -> Single-row index lookup on m using PRIMARY (milestone_id=p.milestone_id)  (cost=0.35 rows=1) (actual time=0.00185..0.00189 rows=1 loops=3)

```

## Q-07 Completed work not yet paid

Expected: Milestones 2,5,9

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

Actual:
```json
[
  [
    2,
    "COMPLETED",
    "600.00"
  ],
  [
    5,
    "APPROVED",
    "500.00"
  ],
  [
    9,
    "APPROVED",
    "500.00"
  ]
]
```

COMPLETED still needs approval; pending and failed are unpaid.

Median latency: 0.187 ms.

EXPLAIN ANALYZE:
```text
-> Nested loop antijoin  (cost=7.41 rows=36) (actual time=0.0192..0.0239 rows=3 loops=1)
    -> Filter: (m.`status` in ('COMPLETED','APPROVED'))  (cost=3.21 rows=6) (actual time=0.00708..0.011 rows=6 loops=1)
        -> Index scan on m using PRIMARY  (cost=3.21 rows=10) (actual time=0.00627..0.00872 rows=10 loops=1)
    -> Single-row index lookup on <subquery2> using <auto_distinct_key> (milestone_id=m.milestone_id)  (cost=1.57..1.57 rows=1) (actual time=0.00195..0.00195 rows=0.5 loops=6)
        -> Materialize with deduplication  (cost=1.45..1.45 rows=6) (actual time=0.00899..0.00899 rows=3 loops=1)
            -> Filter: (p.milestone_id is not null)  (cost=0.85 rows=6) (actual time=0.00426..0.00641 rows=3 loops=1)
                -> Filter: (p.payment_status = 'PAID')  (cost=0.85 rows=6) (actual time=0.00404..0.00599 rows=3 loops=1)
                    -> Table scan on p  (cost=0.85 rows=6) (actual time=0.00279..0.00473 rows=6 loops=1)

```

## Q-08 Jobs above mean maximum budget

Expected: Jobs 3,5,8; mean1062.50

```sql
SELECT job_id,
       budget_max
FROM jobs
WHERE budget_max >
        (SELECT AVG(budget_max)
         FROM jobs)
ORDER BY job_id;
```

Actual:
```json
[
  [
    3,
    "1500.00"
  ],
  [
    5,
    "2000.00"
  ],
  [
    8,
    "1200.00"
  ]
]
```

Scalar non-correlated aggregate subquery.

Median latency: 0.106 ms.

EXPLAIN ANALYZE:
```text
-> Filter: (jobs.budget_max > (select #2))  (cost=0.517 rows=2.67) (actual time=0.00288..0.00446 rows=3 loops=1)
    -> Index scan on jobs using PRIMARY  (cost=0.517 rows=8) (actual time=0.00193..0.00321 rows=8 loops=1)
    -> Select #2 (subquery in condition; run only once)
        -> Aggregate: avg(jobs.budget_max)  (cost=1.85 rows=1) (actual time=0.00647..0.00652 rows=1 loops=1)
            -> Covering index scan on jobs using ix_jobs_status_budget  (cost=1.05 rows=8) (actual time=0.00337..0.00488 rows=8 loops=1)

```

## Q-09 Freelancers with at least three skills

Expected: Freelancers4,6 each3

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

Actual:
```json
[
  [
    4,
    "Database and software specialist",
    3
  ],
  [
    6,
    "Database and software specialist",
    3
  ]
]
```

INNER JOIN with HAVING.

Median latency: 0.173 ms.

EXPLAIN ANALYZE:
```text
-> Sort: f.freelancer_id, f.professional_title  (actual time=0.0466..0.0467 rows=2 loops=1)
    -> Filter: (`count(fs.skill_id)` >= 3)  (actual time=0.0401..0.0411 rows=2 loops=1)
        -> Table scan on <temporary>  (actual time=0.0392..0.0398 rows=5 loops=1)
            -> Aggregate using temporary table  (actual time=0.0387..0.0387 rows=5 loops=1)
                -> Nested loop inner join  (cost=3 rows=10) (actual time=0.0162..0.0258 rows=10 loops=1)
                    -> Table scan on f  (cost=0.75 rows=5) (actual time=0.0104..0.0116 rows=5 loops=1)
                    -> Covering index lookup on fs using PRIMARY (freelancer_id=f.freelancer_id)  (cost=0.29 rows=2) (actual time=0.00182..0.00247 rows=2 loops=5)

```

## Q-10 Contract milestone payment report

Expected: 5 contracts, 2 milestones each; PAID 400,300,0,200,0

```sql
SELECT *
FROM v_contract_overview
ORDER BY contract_id;
```

Actual:
```json
[
  [
    1,
    1,
    4,
    "1000.00",
    "ACTIVE",
    2,
    "1000.00",
    "400.00",
    "600.00"
  ],
  [
    2,
    1,
    5,
    "800.00",
    "ACTIVE",
    2,
    "800.00",
    "300.00",
    "500.00"
  ],
  [
    3,
    2,
    6,
    "1500.00",
    "ACTIVE",
    2,
    "1500.00",
    "0.00",
    "1500.00"
  ],
  [
    4,
    2,
    7,
    "600.00",
    "ACTIVE",
    2,
    "600.00",
    "200.00",
    "400.00"
  ],
  [
    5,
    3,
    4,
    "2000.00",
    "ACTIVE",
    2,
    "2000.00",
    "0.00",
    "2000.00"
  ]
]
```

Separate aggregation avoids repeated milestone totals.

Median latency: 0.522 ms.

EXPLAIN ANALYZE:
```text
-> Sort: v_contract_overview.contract_id  (actual time=0.0829..0.0834 rows=5 loops=1)
    -> Stream results  (cost=5.04 rows=0) (actual time=0.0687..0.0773 rows=5 loops=1)
        -> Left hash join (p.contract_id = c.contract_id)  (cost=5.04 rows=0) (actual time=0.0654..0.0709 rows=5 loops=1)
            -> Nested loop left join  (cost=4.83 rows=15.8) (actual time=0.0225..0.0267 rows=5 loops=1)
                -> Table scan on c  (cost=0.75 rows=5) (actual time=0.00289..0.00402 rows=5 loops=1)
                -> Index lookup on m using <auto_key0> (contract_id=c.contract_id)  (cost=2.84..3.11 rows=2) (actual time=0.00413..0.00435 rows=1 loops=5)
                    -> Materialize  (cost=2.57..2.57 rows=3.16) (actual time=0.0185..0.0185 rows=5 loops=1)
                        -> Group aggregate: count(0), sum(milestones.amount)  (cost=2.25 rows=3.16) (actual time=0.00953..0.0143 rows=5 loops=1)
                            -> Index scan on milestones using fk_milestone_contract  (cost=1.25 rows=10) (actual time=0.0067..0.0106 rows=10 loops=1)
            -> Hash
                -> Table scan on p  (cost=2.5..2.5 rows=0) (actual time=0.0365..0.0368 rows=3 loops=1)
                    -> Materialize  (cost=0..0 rows=0) (actual time=0.0362..0.0362 rows=3 loops=1)
                        -> Table scan on <temporary>  (actual time=0.0301..0.0305 rows=3 loops=1)
                            -> Aggregate using temporary table  (actual time=0.0297..0.0297 rows=3 loops=1)
                                -> Nested loop inner join  (cost=1.2 rows=1) (actual time=0.0197..0.0241 rows=3 loops=1)
                                    -> Filter: (p.payment_status = 'PAID')  (cost=0.85 rows=1) (actual time=0.0146..0.0169 rows=3 loops=1)
                                        -> Table scan on p  (cost=0.85 rows=6) (actual time=0.0125..0.0149 rows=6 loops=1)
                                    -> Single-row index lookup on m using PRIMARY (milestone_id=p.milestone_id)  (cost=0.35 rows=1) (actual time=0.00204..0.00207 rows=1 loops=3)

```

## Q-11 Clients posting the most jobs

Expected: Clients1,2 each3

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

Actual:
```json
[
  [
    1,
    3
  ],
  [
    2,
    3
  ]
]
```

Retains ties rather than LIMIT1.

Median latency: 0.149 ms.

EXPLAIN ANALYZE:
```text
-> Sort: ranked.client_id  (cost=0.45..0.45 rows=0) (actual time=0.0271..0.0272 rows=2 loops=1)
    -> Index lookup on ranked using <auto_key0> (r=1)  (cost=0.35..0.35 rows=1) (actual time=0.0248..0.0255 rows=2 loops=1)
        -> Materialize CTE ranked  (cost=0..0 rows=0) (actual time=0.0239..0.0239 rows=3 loops=1)
            -> Window aggregate: dense_rank() OVER (ORDER BY counts.job_count desc )   (actual time=0.0184..0.0191 rows=3 loops=1)
                -> Sort: counts.job_count DESC  (cost=5.36..5.36 rows=2.83) (actual time=0.0174..0.0175 rows=3 loops=1)
                    -> Table scan on counts  (cost=3.03..4.66 rows=2.83) (actual time=0.0137..0.0142 rows=3 loops=1)
                        -> Materialize CTE counts  (cost=2.13..2.13 rows=2.83) (actual time=0.0133..0.0133 rows=3 loops=1)
                            -> Group aggregate: count(0)  (cost=1.85 rows=2.83) (actual time=0.0091..0.0109 rows=3 loops=1)
                                -> Covering index scan on jobs using fk_jobs_client  (cost=1.05 rows=8) (actual time=0.00732..0.00911 rows=8 loops=1)

```

## Q-12 Contracts at risk by a supplied reference date

Expected: Contracts1..5 each1

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

Actual:
```json
[
  [
    1,
    1
  ],
  [
    2,
    1
  ],
  [
    3,
    1
  ],
  [
    4,
    1
  ],
  [
    5,
    1
  ]
]
```

Reference date is30 days after seed date; excludes approved work.

Median latency: 0.197 ms.

EXPLAIN ANALYZE:
```text
-> Group aggregate: count(m.milestone_id)  (cost=2.85 rows=2.45) (actual time=0.0245..0.0353 rows=5 loops=1)
    -> Nested loop inner join  (cost=2.25 rows=6) (actual time=0.018..0.0323 rows=5 loops=1)
        -> Filter: (c.`status` = 'ACTIVE')  (cost=0.75 rows=1) (actual time=0.00727..0.00894 rows=5 loops=1)
            -> Index scan on c using PRIMARY  (cost=0.75 rows=5) (actual time=0.00664..0.00774 rows=5 loops=1)
        -> Filter: ((m.`status` in ('PENDING','IN_PROGRESS','COMPLETED')) and (m.due_date < <cache>((curdate() + interval 30 day))))  (cost=1.1 rows=6) (actual time=0.00395..0.00435 rows=1 loops=5)
            -> Index lookup on m using fk_milestone_contract (contract_id=c.contract_id)  (cost=1.1 rows=10) (actual time=0.00308..0.0036 rows=2 loops=5)

```

## Scale benchmark

Isolated identical schema with5000 jobs and10000 proposals;1 warmup plus30 measured runs per plan. Outputs identical. Cold-cache behavior, remote network and concurrent production load are not measured.

index_allowed: median 0.181 ms.

```sql
SELECT job_id,budget_max FROM jobs  WHERE status='OPEN' AND budget_max>=4800 ORDER BY budget_max DESC LIMIT 20;
```

```text
-> Limit: 20 row(s)  (cost=41 rows=20) (actual time=0.0133..0.019 rows=20 loops=1)
    -> Filter: ((jobs.`status` = 'OPEN') and (jobs.budget_max >= 4800.00))  (cost=41 rows=201) (actual time=0.0129..0.0177 rows=20 loops=1)
        -> Covering index range scan on jobs using ix_jobs_status_budget over (status = 'OPEN' AND 4800.00 <= budget_max) (reverse)  (cost=41 rows=201) (actual time=0.0113..0.0138 rows=20 loops=1)

```

index_ignored: median 1.383 ms.

```sql
SELECT job_id,budget_max FROM jobs IGNORE INDEX (ix_jobs_status_budget) WHERE status='OPEN' AND budget_max>=4800 ORDER BY budget_max DESC LIMIT 20;
```

```text
-> Limit: 20 row(s)  (cost=497 rows=20) (actual time=1.33..1.33 rows=20 loops=1)
    -> Sort: jobs.budget_max DESC, limit input to 20 row(s) per chunk  (cost=497 rows=4902) (actual time=1.33..1.33 rows=20 loops=1)
        -> Filter: ((jobs.`status` = 'OPEN') and (jobs.budget_max >= 4800.00))  (cost=497 rows=4902) (actual time=1.24..1.29 rows=201 loops=1)
            -> Table scan on jobs  (cost=497 rows=4902) (actual time=0.0249..0.791 rows=5000 loops=1)

```
