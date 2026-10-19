USE mini_upwork;
CREATE VIEW v_job_proposals AS
SELECT j.job_id, j.client_id, j.title, j.status, j.budget_max,
       COUNT(p.proposal_id) AS proposal_count,
       COALESCE(SUM(p.status IN ('CLIENT_ACCEPTED', 'CONFIRMED')), 0) AS selected_count
FROM jobs AS j LEFT JOIN proposals AS p ON p.job_id = j.job_id
GROUP BY j.job_id, j.client_id, j.title, j.status, j.budget_max;
CREATE VIEW v_contract_overview AS
SELECT c.contract_id, c.client_id, c.freelancer_id, c.total_amount, c.status,
       COALESCE(m.milestone_count, 0) AS milestone_count,
       COALESCE(m.allocated_amount, 0) AS allocated_amount,
       COALESCE(p.paid_amount, 0) AS paid_amount,
       c.total_amount - COALESCE(p.paid_amount, 0) AS outstanding_amount
FROM contracts AS c
LEFT JOIN (SELECT contract_id, COUNT(*) AS milestone_count, SUM(amount) AS allocated_amount
           FROM milestones GROUP BY contract_id) AS m ON m.contract_id = c.contract_id
LEFT JOIN (SELECT m.contract_id, SUM(p.amount) AS paid_amount
           FROM milestones AS m JOIN payments AS p ON p.milestone_id = m.milestone_id
           WHERE p.payment_status = 'PAID' GROUP BY m.contract_id) AS p
    ON p.contract_id = c.contract_id;
CREATE VIEW v_client_spend AS
SELECT c.client_id, COUNT(p.payment_id) AS paid_count, COALESCE(SUM(p.amount), 0) AS paid_amount
FROM clients AS c LEFT JOIN payments AS p ON p.payer_id = c.client_id AND p.payment_status = 'PAID'
GROUP BY c.client_id;
CREATE INDEX ix_jobs_status_budget ON jobs (status, budget_max);
CREATE INDEX ix_milestones_status_due ON milestones (status, due_date);
-- Foreign keys create supporting indexes automatically; no duplicate job_id index:
-- uq_proposal_freelancer_job already has job_id as its leftmost prefix.
