-- Exact row counts; do not use approximate INFORMATION_SCHEMA.TABLE_ROWS.
USE mini_upwork;
WITH row_counts AS (
    SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL
    SELECT 'clients' AS table_name, COUNT(*) AS row_count FROM clients
UNION ALL
    SELECT 'freelancers' AS table_name, COUNT(*) AS row_count FROM freelancers
UNION ALL
    SELECT 'skills' AS table_name, COUNT(*) AS row_count FROM skills
UNION ALL
    SELECT 'freelancer_skills' AS table_name, COUNT(*) AS row_count FROM freelancer_skills
UNION ALL
    SELECT 'job_categories' AS table_name, COUNT(*) AS row_count FROM job_categories
UNION ALL
    SELECT 'jobs' AS table_name, COUNT(*) AS row_count FROM jobs
UNION ALL
    SELECT 'proposals' AS table_name, COUNT(*) AS row_count FROM proposals
UNION ALL
    SELECT 'contracts' AS table_name, COUNT(*) AS row_count FROM contracts
UNION ALL
    SELECT 'milestones' AS table_name, COUNT(*) AS row_count FROM milestones
UNION ALL
    SELECT 'payments' AS table_name, COUNT(*) AS row_count FROM payments
)
SELECT table_name, row_count, SUM(row_count) OVER () AS total_rows
FROM row_counts
ORDER BY table_name;
