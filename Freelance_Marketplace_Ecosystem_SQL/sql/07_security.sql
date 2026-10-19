USE mini_upwork;
CREATE ROLE IF NOT EXISTS 'market_client', 'market_freelancer', 'market_payment', 'market_analyst';
GRANT EXECUTE ON PROCEDURE mini_upwork.sp_select_proposal TO 'market_client';
GRANT EXECUTE ON PROCEDURE mini_upwork.sp_advance_milestone TO 'market_client';
GRANT EXECUTE ON PROCEDURE mini_upwork.sp_post_job TO 'market_client';
GRANT EXECUTE ON PROCEDURE mini_upwork.sp_add_milestone TO 'market_client';
GRANT EXECUTE ON PROCEDURE mini_upwork.sp_confirm_proposal TO 'market_freelancer';
GRANT EXECUTE ON PROCEDURE mini_upwork.sp_advance_milestone TO 'market_freelancer';
GRANT EXECUTE ON PROCEDURE mini_upwork.sp_submit_proposal TO 'market_freelancer';
GRANT EXECUTE ON PROCEDURE mini_upwork.sp_record_payment TO 'market_payment';
GRANT SELECT ON mini_upwork.v_job_proposals TO 'market_analyst';
GRANT SELECT ON mini_upwork.v_contract_overview TO 'market_analyst';
GRANT SELECT ON mini_upwork.v_client_spend TO 'market_analyst';
-- All demonstration accounts are initially locked; no passwords in repository.
CREATE USER IF NOT EXISTS 'client_1'@'localhost' ACCOUNT LOCK;
GRANT 'market_client' TO 'client_1'@'localhost';
SET DEFAULT ROLE 'market_client' TO 'client_1'@'localhost';
CREATE USER IF NOT EXISTS 'client_2'@'localhost' ACCOUNT LOCK;
GRANT 'market_client' TO 'client_2'@'localhost';
SET DEFAULT ROLE 'market_client' TO 'client_2'@'localhost';
CREATE USER IF NOT EXISTS 'client_3'@'localhost' ACCOUNT LOCK;
GRANT 'market_client' TO 'client_3'@'localhost';
SET DEFAULT ROLE 'market_client' TO 'client_3'@'localhost';
CREATE USER IF NOT EXISTS 'freelancer_4'@'localhost' ACCOUNT LOCK;
GRANT 'market_freelancer' TO 'freelancer_4'@'localhost';
SET DEFAULT ROLE 'market_freelancer' TO 'freelancer_4'@'localhost';
CREATE USER IF NOT EXISTS 'freelancer_5'@'localhost' ACCOUNT LOCK;
GRANT 'market_freelancer' TO 'freelancer_5'@'localhost';
SET DEFAULT ROLE 'market_freelancer' TO 'freelancer_5'@'localhost';
CREATE USER IF NOT EXISTS 'freelancer_6'@'localhost' ACCOUNT LOCK;
GRANT 'market_freelancer' TO 'freelancer_6'@'localhost';
SET DEFAULT ROLE 'market_freelancer' TO 'freelancer_6'@'localhost';
CREATE USER IF NOT EXISTS 'freelancer_7'@'localhost' ACCOUNT LOCK;
GRANT 'market_freelancer' TO 'freelancer_7'@'localhost';
SET DEFAULT ROLE 'market_freelancer' TO 'freelancer_7'@'localhost';
CREATE USER IF NOT EXISTS 'freelancer_8'@'localhost' ACCOUNT LOCK;
GRANT 'market_freelancer' TO 'freelancer_8'@'localhost';
SET DEFAULT ROLE 'market_freelancer' TO 'freelancer_8'@'localhost';
CREATE USER IF NOT EXISTS 'payment_service'@'localhost' ACCOUNT LOCK;
GRANT 'market_payment' TO 'payment_service'@'localhost';
SET DEFAULT ROLE 'market_payment' TO 'payment_service'@'localhost';
CREATE USER IF NOT EXISTS 'report_reader'@'localhost' ACCOUNT LOCK;
GRANT 'market_analyst' TO 'report_reader'@'localhost';
SET DEFAULT ROLE 'market_analyst' TO 'report_reader'@'localhost';
-- Demonstrate temporary privilege and revocation without granting table DML.
GRANT SELECT ON mini_upwork.skills TO 'market_analyst';
REVOKE SELECT ON mini_upwork.skills FROM 'market_analyst';
-- Production: configure strong secrets out of band, REQUIRE SSL for TCP users, then unlock.
-- Definer must be a dedicated least-privilege account in deployment, not root.
