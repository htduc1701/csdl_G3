USE mini_upwork;
SELECT 'users' AS table_name,COUNT(*) AS row_count FROM users
UNION ALL
SELECT 'clients' AS table_name,COUNT(*) AS row_count FROM clients
UNION ALL
SELECT 'freelancers' AS table_name,COUNT(*) AS row_count FROM freelancers
UNION ALL
SELECT 'skills' AS table_name,COUNT(*) AS row_count FROM skills
UNION ALL
SELECT 'freelancer_skills' AS table_name,COUNT(*) AS row_count FROM freelancer_skills
UNION ALL
SELECT 'job_categories' AS table_name,COUNT(*) AS row_count FROM job_categories
UNION ALL
SELECT 'jobs' AS table_name,COUNT(*) AS row_count FROM jobs
UNION ALL
SELECT 'proposals' AS table_name,COUNT(*) AS row_count FROM proposals
UNION ALL
SELECT 'contracts' AS table_name,COUNT(*) AS row_count FROM contracts
UNION ALL
SELECT 'milestones' AS table_name,COUNT(*) AS row_count FROM milestones
UNION ALL
SELECT 'payments' AS table_name,COUNT(*) AS row_count FROM payments
UNION ALL
SELECT 'contract_reviews' AS table_name,COUNT(*) AS row_count FROM contract_reviews;
