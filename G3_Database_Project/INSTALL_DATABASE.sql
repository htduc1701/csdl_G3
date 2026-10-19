-- G3 Mini-Upwork: fresh installation with 7,223 rows, verified on MySQL 8.0.42.
-- Existing tables are not dropped. Stop on any error.


-- File: 01_schema.sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- MySQL 8.0.42; requires >= 8.0.16 for enforced CHECK. Non-destructive install.
CREATE DATABASE IF NOT EXISTS mini_upwork CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE mini_upwork;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ONLY_FULL_GROUP_BY,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE TABLE users (
    user_id INT NOT NULL AUTO_INCREMENT,
    email VARCHAR(150) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NULL DEFAULT NULL,
    user_type VARCHAR(20) NOT NULL,
    PRIMARY KEY (user_id),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT ck_users_type CHECK (user_type IN ('CLIENT', 'FREELANCER'))
) ENGINE = InnoDB;

CREATE TABLE clients (
    client_id INT NOT NULL,
    company_name VARCHAR(150) NULL DEFAULT NULL,
    company_description TEXT NULL DEFAULT NULL,
    location VARCHAR(150) NULL DEFAULT NULL,
    PRIMARY KEY (client_id),
    CONSTRAINT fk_clients_user FOREIGN KEY (client_id) REFERENCES users (user_id)
) ENGINE = InnoDB;

CREATE TABLE freelancers (
    freelancer_id INT NOT NULL,
    professional_title VARCHAR(150) NOT NULL DEFAULT 'Not specified',
    bio TEXT NULL DEFAULT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    experience_level VARCHAR(20) NOT NULL DEFAULT 'INTERMEDIATE',
    PRIMARY KEY (freelancer_id),
    CONSTRAINT fk_freelancers_user FOREIGN KEY (freelancer_id) REFERENCES users (user_id),
    CONSTRAINT ck_freelancer_rate CHECK (hourly_rate >= 0),
    CONSTRAINT ck_freelancer_level CHECK (experience_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT'))
) ENGINE = InnoDB;

CREATE TABLE skills (
    skill_id INT NOT NULL AUTO_INCREMENT,
    skill_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (skill_id),
    CONSTRAINT uq_skills_name UNIQUE (skill_name)
) ENGINE = InnoDB;

CREATE TABLE freelancer_skills (
    freelancer_id INT NOT NULL,
    skill_id INT NOT NULL,
    skill_level VARCHAR(20) NOT NULL DEFAULT 'INTERMEDIATE',
    PRIMARY KEY (freelancer_id, skill_id),
    CONSTRAINT fk_fs_freelancer FOREIGN KEY (freelancer_id) REFERENCES freelancers (freelancer_id),
    CONSTRAINT fk_fs_skill FOREIGN KEY (skill_id) REFERENCES skills (skill_id),
    CONSTRAINT ck_fs_level CHECK (skill_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT'))
) ENGINE = InnoDB;

CREATE TABLE job_categories (
    category_id INT NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL,
    description TEXT NULL DEFAULT NULL,
    PRIMARY KEY (category_id),
    CONSTRAINT uq_categories_name UNIQUE (category_name)
) ENGINE = InnoDB;

CREATE TABLE jobs (
    job_id INT NOT NULL AUTO_INCREMENT,
    client_id INT NOT NULL,
    category_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    budget_min DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    budget_max DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    deadline DATE NULL DEFAULT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (job_id),
    CONSTRAINT fk_jobs_client FOREIGN KEY (client_id) REFERENCES clients (client_id),
    CONSTRAINT fk_jobs_category FOREIGN KEY (category_id) REFERENCES job_categories (category_id),
    CONSTRAINT ck_jobs_budget CHECK (budget_min >= 0 AND budget_max >= budget_min),
    CONSTRAINT ck_jobs_dates CHECK (deadline IS NULL OR deadline > DATE(created_at)),
    CONSTRAINT ck_jobs_status CHECK (status IN ('OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
) ENGINE = InnoDB;

CREATE TABLE proposals (
    proposal_id INT NOT NULL AUTO_INCREMENT,
    job_id INT NOT NULL,
    freelancer_id INT NOT NULL,
    proposed_amount DECIMAL(15,2) NOT NULL,
    cover_letter TEXT NOT NULL,
    estimated_days INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    selected_job_id INT GENERATED ALWAYS AS (CASE WHEN status IN ('CLIENT_ACCEPTED', 'CONFIRMED') THEN job_id ELSE NULL END) STORED,
    PRIMARY KEY (proposal_id),
    CONSTRAINT fk_proposals_job FOREIGN KEY (job_id) REFERENCES jobs (job_id),
    CONSTRAINT fk_proposals_freelancer FOREIGN KEY (freelancer_id) REFERENCES freelancers (freelancer_id),
    CONSTRAINT uq_proposal_freelancer_job UNIQUE (job_id, freelancer_id),
    CONSTRAINT uq_selected_job UNIQUE (selected_job_id),
    CONSTRAINT ck_proposal_amount CHECK (proposed_amount > 0),
    CONSTRAINT ck_proposal_days CHECK (estimated_days > 0),
    CONSTRAINT ck_proposal_status CHECK (status IN ('PENDING', 'CLIENT_ACCEPTED', 'CONFIRMED', 'REJECTED', 'WITHDRAWN'))
) ENGINE = InnoDB;

CREATE TABLE contracts (
    contract_id INT NOT NULL AUTO_INCREMENT,
    proposal_id INT NOT NULL,
    client_id INT NOT NULL,
    freelancer_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL DEFAULT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    PRIMARY KEY (contract_id),
    CONSTRAINT fk_contract_proposal FOREIGN KEY (proposal_id) REFERENCES proposals (proposal_id),
    CONSTRAINT uq_contract_proposal UNIQUE (proposal_id),
    CONSTRAINT fk_contract_client FOREIGN KEY (client_id) REFERENCES clients (client_id),
    CONSTRAINT fk_contract_freelancer FOREIGN KEY (freelancer_id) REFERENCES freelancers (freelancer_id),
    CONSTRAINT ck_contract_amount CHECK (total_amount > 0),
    CONSTRAINT ck_contract_dates CHECK (end_date IS NULL OR end_date > start_date),
    CONSTRAINT ck_contract_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED'))
) ENGINE = InnoDB;

CREATE TABLE milestones (
    milestone_id INT NOT NULL AUTO_INCREMENT,
    contract_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NULL DEFAULT NULL,
    amount DECIMAL(15,2) NOT NULL,
    due_date DATE NULL DEFAULT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    PRIMARY KEY (milestone_id),
    CONSTRAINT fk_milestone_contract FOREIGN KEY (contract_id) REFERENCES contracts (contract_id),
    CONSTRAINT ck_milestone_amount CHECK (amount > 0),
    CONSTRAINT ck_milestone_status CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'APPROVED'))
) ENGINE = InnoDB;

CREATE TABLE payments (
    payment_id INT NOT NULL AUTO_INCREMENT,
    milestone_id INT NOT NULL,
    payer_id INT NOT NULL,
    payee_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(50) NOT NULL,
    paid_milestone_id INT GENERATED ALWAYS AS (CASE WHEN payment_status = 'PAID' THEN milestone_id ELSE NULL END) STORED,
    PRIMARY KEY (payment_id),
    CONSTRAINT fk_payment_milestone FOREIGN KEY (milestone_id) REFERENCES milestones (milestone_id),
    CONSTRAINT fk_payment_payer FOREIGN KEY (payer_id) REFERENCES users (user_id),
    CONSTRAINT fk_payment_payee FOREIGN KEY (payee_id) REFERENCES users (user_id),
    CONSTRAINT uq_paid_milestone UNIQUE (paid_milestone_id),
    CONSTRAINT ck_payment_amount CHECK (amount > 0),
    CONSTRAINT ck_payment_status CHECK (payment_status IN ('PENDING', 'PAID', 'FAILED')),
    CONSTRAINT ck_payment_method CHECK (payment_method IN ('PAYPAL', 'CREDIT_CARD', 'BANK_TRANSFER'))
) ENGINE = InnoDB;


-- File: 02_triggers.sql
USE mini_upwork;
DELIMITER $$

CREATE TRIGGER tr_users_create_subtype
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.user_type = 'CLIENT' THEN
        INSERT INTO clients (client_id) VALUES (NEW.user_id);
    ELSE
        INSERT INTO freelancers (freelancer_id) VALUES (NEW.user_id);
    END IF;
END$$

CREATE TRIGGER tr_users_identity_immutable
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.user_id <> OLD.user_id OR NEW.user_type <> OLD.user_type THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 user identity and subtype are immutable';
    END IF;
END$$

CREATE TRIGGER tr_clients_type
BEFORE INSERT ON clients
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(20);
    SELECT user_type INTO v_type FROM users WHERE user_id = NEW.client_id;
    IF v_type IS NULL OR v_type <> 'CLIENT' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 subtype must match parent user_type';
    END IF;
END$$

CREATE TRIGGER tr_clients_identity
BEFORE UPDATE ON clients
FOR EACH ROW
BEGIN
    IF NEW.client_id <> OLD.client_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 subtype identity is immutable';
    END IF;
END$$

CREATE TRIGGER tr_clients_retain
BEFORE DELETE ON clients
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 total specialization requires subtype retention';
END$$

CREATE TRIGGER tr_freelancers_type
BEFORE INSERT ON freelancers
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(20);
    SELECT user_type INTO v_type FROM users WHERE user_id = NEW.freelancer_id;
    IF v_type IS NULL OR v_type <> 'FREELANCER' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 subtype must match parent user_type';
    END IF;
END$$

CREATE TRIGGER tr_freelancers_identity
BEFORE UPDATE ON freelancers
FOR EACH ROW
BEGIN
    IF NEW.freelancer_id <> OLD.freelancer_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 subtype identity is immutable';
    END IF;
END$$

CREATE TRIGGER tr_freelancers_retain
BEFORE DELETE ON freelancers
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 total specialization requires subtype retention';
END$$

CREATE TRIGGER tr_jobs_owner
BEFORE UPDATE ON jobs
FOR EACH ROW
BEGIN
    IF NEW.job_id <> OLD.job_id OR NEW.client_id <> OLD.client_id OR NEW.created_at <> OLD.created_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job owner identity and creation time are immutable';
    END IF;
END$$

CREATE TRIGGER tr_proposals_initial
BEFORE INSERT ON proposals
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM jobs WHERE job_id = NEW.job_id FOR UPDATE;
    IF v_status IS NULL OR v_status <> 'OPEN' OR NEW.status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proposal requires OPEN job and initial PENDING status';
    END IF;
END$$

CREATE TRIGGER tr_proposals_transition
BEFORE UPDATE ON proposals
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM jobs WHERE job_id = OLD.job_id FOR UPDATE;
    IF NEW.proposal_id <> OLD.proposal_id OR NEW.job_id <> OLD.job_id
       OR NEW.freelancer_id <> OLD.freelancer_id OR NEW.submitted_at <> OLD.submitted_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proposal identity is immutable';
    END IF;
    IF OLD.status <> 'PENDING' AND (NEW.proposed_amount <> OLD.proposed_amount
       OR NEW.estimated_days <> OLD.estimated_days) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selected proposal terms are immutable';
    END IF;
    IF NEW.status <> OLD.status AND NOT (
        (OLD.status = 'PENDING' AND NEW.status IN ('CLIENT_ACCEPTED', 'REJECTED', 'WITHDRAWN'))
        OR (OLD.status = 'CLIENT_ACCEPTED' AND NEW.status IN ('CONFIRMED', 'REJECTED', 'WITHDRAWN'))
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-11 illegal proposal transition';
    END IF;
    IF NEW.status IN ('CLIENT_ACCEPTED', 'CONFIRMED') AND v_status <> 'OPEN' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selection requires OPEN job';
    END IF;
END$$

CREATE TRIGGER tr_contracts_validate
BEFORE INSERT ON contracts
FOR EACH ROW
BEGIN
    DECLARE v_freelancer INT;
    DECLARE v_client INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_amount DECIMAL(15,2);
    SELECT p.freelancer_id, j.client_id, p.status, p.proposed_amount
      INTO v_freelancer, v_client, v_status, v_amount
    FROM proposals AS p JOIN jobs AS j ON j.job_id = p.job_id
    WHERE p.proposal_id = NEW.proposal_id;
    IF v_status IS NULL OR v_status <> 'CONFIRMED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-11 requires confirmed proposal';
    END IF;
    IF NEW.client_id <> v_client OR NEW.freelancer_id <> v_freelancer
       OR NEW.total_amount <> v_amount OR NEW.status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-12 contract parties or terms mismatch';
    END IF;
END$$

CREATE TRIGGER tr_proposals_create_contract
AFTER UPDATE ON proposals
FOR EACH ROW
BEGIN
    IF OLD.status = 'CLIENT_ACCEPTED' AND NEW.status = 'CONFIRMED' THEN
        INSERT INTO contracts (proposal_id, client_id, freelancer_id, start_date, end_date, total_amount)
        SELECT NEW.proposal_id, client_id, NEW.freelancer_id, CURRENT_DATE,
               DATE_ADD(CURRENT_DATE, INTERVAL NEW.estimated_days DAY), NEW.proposed_amount
        FROM jobs WHERE job_id = NEW.job_id;
        UPDATE jobs SET status = 'IN_PROGRESS' WHERE job_id = NEW.job_id;
    END IF;
END$$

CREATE TRIGGER tr_contracts_update
BEFORE UPDATE ON contracts
FOR EACH ROW
BEGIN
    DECLARE v_sum DECIMAL(15,2);
    DECLARE v_bad INT;
    IF @@transaction_isolation <> 'READ-COMMITTED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone budget writes require READ COMMITTED';
    END IF;
    IF NEW.contract_id <> OLD.contract_id OR NEW.proposal_id <> OLD.proposal_id
       OR NEW.client_id <> OLD.client_id OR NEW.freelancer_id <> OLD.freelancer_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract identity and parties are immutable';
    END IF;
    SELECT COALESCE(SUM(amount), 0), COUNT(CASE WHEN due_date < NEW.start_date
        OR (NEW.end_date IS NOT NULL AND due_date > NEW.end_date) THEN 1 END)
      INTO v_sum, v_bad FROM milestones WHERE contract_id = OLD.contract_id;
    IF v_sum > NEW.total_amount OR v_bad > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-14 contract update invalidates milestones';
    END IF;
    IF NEW.status <> OLD.status THEN
        IF OLD.status <> 'ACTIVE' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Terminal contract is immutable';
        END IF;
        IF NEW.status = 'COMPLETED' THEN
            SELECT COUNT(*) INTO v_bad FROM milestones AS m
            WHERE m.contract_id = OLD.contract_id AND (m.status <> 'APPROVED'
                OR NOT EXISTS (SELECT 1 FROM payments AS p WHERE p.milestone_id = m.milestone_id
                    AND p.payment_status = 'PAID'));
            IF v_sum <> NEW.total_amount OR v_bad > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Completion requires fully allocated paid milestones';
            END IF;
        ELSEIF NEW.status = 'CANCELLED' THEN
            SELECT COUNT(*) INTO v_bad FROM milestones AS m JOIN payments AS p
                ON p.milestone_id = m.milestone_id
            WHERE m.contract_id = OLD.contract_id AND p.payment_status = 'PAID';
            IF v_bad > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cancellation with paid funds needs out of scope refund';
            END IF;
        END IF;
    END IF;
END$$

CREATE TRIGGER tr_milestones_insert
BEFORE INSERT ON milestones
FOR EACH ROW
BEGIN
    DECLARE v_total DECIMAL(15,2);
    DECLARE v_sum DECIMAL(15,2);
    DECLARE v_start DATE;
    DECLARE v_end DATE;
    DECLARE v_status VARCHAR(20);
    IF @@transaction_isolation <> 'READ-COMMITTED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone budget writes require READ COMMITTED';
    END IF;
    SELECT total_amount, start_date, end_date, status INTO v_total, v_start, v_end, v_status
    FROM contracts WHERE contract_id = NEW.contract_id FOR UPDATE;
    IF v_total IS NULL OR v_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone requires ACTIVE contract';
    END IF;
    IF NEW.due_date < v_start OR (v_end IS NOT NULL AND NEW.due_date > v_end) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone date outside contract';
    END IF;
    IF NEW.status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone starts PENDING';
    END IF;
    SELECT COALESCE(SUM(amount), 0) INTO v_sum FROM milestones
    WHERE contract_id = NEW.contract_id;
    IF v_sum + NEW.amount > v_total THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-14 milestone sum exceeds contract';
    END IF;
END$$

CREATE TRIGGER tr_milestones_update
BEFORE UPDATE ON milestones
FOR EACH ROW
BEGIN
    DECLARE v_total DECIMAL(15,2);
    DECLARE v_sum DECIMAL(15,2);
    DECLARE v_start DATE;
    DECLARE v_end DATE;
    DECLARE v_status VARCHAR(20);
    IF @@transaction_isolation <> 'READ-COMMITTED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone budget writes require READ COMMITTED';
    END IF;
    SELECT total_amount, start_date, end_date, status INTO v_total, v_start, v_end, v_status
    FROM contracts WHERE contract_id = NEW.contract_id FOR UPDATE;
    IF v_total IS NULL OR v_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone requires ACTIVE contract';
    END IF;
    IF NEW.due_date < v_start OR (v_end IS NOT NULL AND NEW.due_date > v_end) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone date outside contract';
    END IF;
    IF NEW.milestone_id <> OLD.milestone_id OR NEW.contract_id <> OLD.contract_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone identity is immutable';
    END IF;
    IF NEW.status <> OLD.status AND NOT (
        (OLD.status = 'PENDING' AND NEW.status = 'IN_PROGRESS')
        OR (OLD.status = 'IN_PROGRESS' AND NEW.status = 'COMPLETED')
        OR (OLD.status = 'COMPLETED' AND NEW.status = 'APPROVED')
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-15 illegal milestone transition';
    END IF;
    IF OLD.status <> 'PENDING' AND (NEW.amount <> OLD.amount OR NOT (NEW.due_date <=> OLD.due_date)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Started milestone terms are immutable';
    END IF;
    SELECT COALESCE(SUM(amount), 0) INTO v_sum FROM milestones
    WHERE contract_id = NEW.contract_id AND milestone_id <> OLD.milestone_id;
    IF v_sum + NEW.amount > v_total THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-14 milestone sum exceeds contract';
    END IF;
END$$

CREATE TRIGGER tr_milestones_delete
BEFORE DELETE ON milestones
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestones retained for work and financial audit';
END$$

CREATE TRIGGER tr_payments_insert
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_amount DECIMAL(15,2);
    DECLARE v_status VARCHAR(20);
    DECLARE v_client INT;
    DECLARE v_freelancer INT;
    DECLARE v_contract_status VARCHAR(20);
    SELECT m.amount, m.status, c.client_id, c.freelancer_id, c.status
      INTO v_amount, v_status, v_client, v_freelancer, v_contract_status
    FROM milestones AS m JOIN contracts AS c ON c.contract_id = m.contract_id
    WHERE m.milestone_id = NEW.milestone_id FOR UPDATE;
    IF v_status IS NULL OR v_status <> 'APPROVED' OR v_contract_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-15 payment requires APPROVED active work';
    END IF;
    IF NEW.payer_id <> v_client OR NEW.payee_id <> v_freelancer OR NEW.amount <> v_amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-16 payment parties or amount mismatch';
    END IF;

END$$

CREATE TRIGGER tr_payments_update
BEFORE UPDATE ON payments
FOR EACH ROW
BEGIN
    DECLARE v_amount DECIMAL(15,2);
    DECLARE v_status VARCHAR(20);
    DECLARE v_client INT;
    DECLARE v_freelancer INT;
    DECLARE v_contract_status VARCHAR(20);
    SELECT m.amount, m.status, c.client_id, c.freelancer_id, c.status
      INTO v_amount, v_status, v_client, v_freelancer, v_contract_status
    FROM milestones AS m JOIN contracts AS c ON c.contract_id = m.contract_id
    WHERE m.milestone_id = NEW.milestone_id FOR UPDATE;
    IF v_status IS NULL OR v_status <> 'APPROVED' OR v_contract_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-15 payment requires APPROVED active work';
    END IF;
    IF NEW.payer_id <> v_client OR NEW.payee_id <> v_freelancer OR NEW.amount <> v_amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-16 payment parties or amount mismatch';
    END IF;
    IF NEW.payment_id <> OLD.payment_id OR NEW.milestone_id <> OLD.milestone_id
        OR NEW.payer_id <> OLD.payer_id OR NEW.payee_id <> OLD.payee_id
        OR NEW.amount <> OLD.amount OR NEW.payment_method <> OLD.payment_method THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment evidence is immutable';
    END IF;
    IF OLD.payment_status <> 'PENDING' AND NEW.payment_status <> OLD.payment_status THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Terminal payment cannot change status';
    END IF;

END$$

CREATE TRIGGER tr_payments_delete
BEFORE DELETE ON payments
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment evidence cannot be deleted';
END$$

DELIMITER ;
DELIMITER $$
CREATE TRIGGER tr_contracts_retain
BEFORE DELETE ON contracts
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-11 confirmed contract must be retained';
END$$
DELIMITER ;


-- File: 03_views_indexes.sql
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


-- File: 04_procedures.sql
USE mini_upwork;
DELIMITER $$

CREATE PROCEDURE sp_select_proposal (IN p_actor INT, IN p_proposal INT)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_client INT;
    DECLARE v_job INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    IF p_actor IS NULL OR SUBSTRING_INDEX(USER(), '@', 1) <> CONCAT('client_', p_actor) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Actor does not match authenticated client';
    END IF;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;
    SELECT job_id INTO v_job FROM proposals WHERE proposal_id = p_proposal;
    SELECT client_id INTO v_client FROM jobs WHERE job_id = v_job FOR UPDATE;
    IF p_actor IS NULL OR v_client IS NULL OR v_client <> p_actor THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Client does not own job';
    END IF;
    UPDATE proposals SET status = 'CLIENT_ACCEPTED' WHERE proposal_id = p_proposal AND status = 'PENDING';
    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proposal is not pending';
    END IF;
    COMMIT;
END$$

CREATE PROCEDURE sp_confirm_proposal (IN p_actor INT, IN p_proposal INT)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_job INT;
    DECLARE v_lock INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    IF p_actor IS NULL OR SUBSTRING_INDEX(USER(), '@', 1) <> CONCAT('freelancer_', p_actor) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Actor does not match authenticated freelancer';
    END IF;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;
    SELECT job_id INTO v_job FROM proposals WHERE proposal_id = p_proposal;
    SELECT job_id INTO v_lock FROM jobs WHERE job_id = v_job FOR UPDATE;
    UPDATE proposals SET status = 'CONFIRMED'
    WHERE proposal_id = p_proposal AND freelancer_id = p_actor AND status = 'CLIENT_ACCEPTED';
    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Freelancer cannot confirm this proposal';
    END IF;
    COMMIT;
END$$

CREATE PROCEDURE sp_advance_milestone (IN p_actor INT, IN p_milestone INT, IN p_status VARCHAR(20))
SQL SECURITY DEFINER
BEGIN
    DECLARE v_client INT;
    DECLARE v_freelancer INT;
    DECLARE v_contract INT;
    DECLARE v_lock INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;
    SELECT contract_id INTO v_contract FROM milestones WHERE milestone_id = p_milestone;
    SELECT client_id, freelancer_id INTO v_client, v_freelancer
    FROM contracts WHERE contract_id = v_contract FOR UPDATE;
    IF p_status = 'APPROVED' THEN
        IF p_actor IS NULL OR v_client IS NULL OR p_actor <> v_client OR SUBSTRING_INDEX(USER(), '@', 1) <> CONCAT('client_', p_actor) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only owning client may approve';
        END IF;
    ELSEIF p_status IN ('IN_PROGRESS', 'COMPLETED') THEN
        IF p_actor IS NULL OR v_freelancer IS NULL OR p_actor <> v_freelancer OR SUBSTRING_INDEX(USER(), '@', 1) <> CONCAT('freelancer_', p_actor) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only assigned freelancer may submit work';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unsupported milestone action';
    END IF;
    UPDATE milestones SET status = p_status WHERE milestone_id = p_milestone;
    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestone action did not change state';
    END IF;
    COMMIT;
END$$

CREATE PROCEDURE sp_submit_proposal (IN p_actor INT, IN p_job INT, IN p_amount DECIMAL(15,2), IN p_letter TEXT, IN p_days INT)
SQL SECURITY DEFINER
BEGIN
    IF p_actor IS NULL OR SUBSTRING_INDEX(USER(), '@', 1) <> CONCAT('freelancer_', p_actor) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Actor does not match authenticated freelancer';
    END IF;
    INSERT INTO proposals (job_id, freelancer_id, proposed_amount, cover_letter, estimated_days)
    VALUES (p_job, p_actor, p_amount, p_letter, p_days);
END$$

CREATE PROCEDURE sp_post_job (IN p_actor INT, IN p_category INT, IN p_title VARCHAR(200), IN p_description TEXT, IN p_min DECIMAL(15,2), IN p_max DECIMAL(15,2), IN p_deadline DATE)
SQL SECURITY DEFINER
BEGIN
    IF p_actor IS NULL OR SUBSTRING_INDEX(USER(), '@', 1) <> CONCAT('client_', p_actor) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Actor does not match authenticated client';
    END IF;
    INSERT INTO jobs (client_id, category_id, title, description, budget_min, budget_max, deadline)
    VALUES (p_actor, p_category, p_title, p_description, p_min, p_max, p_deadline);
END$$

CREATE PROCEDURE sp_add_milestone (IN p_actor INT, IN p_contract INT, IN p_title VARCHAR(200), IN p_amount DECIMAL(15,2), IN p_due DATE)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_client INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;
    SELECT client_id INTO v_client FROM contracts WHERE contract_id = p_contract FOR UPDATE;
    IF p_actor IS NULL OR v_client IS NULL OR p_actor <> v_client OR SUBSTRING_INDEX(USER(), '@', 1) <> CONCAT('client_', p_actor) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only owning client may allocate milestones';
    END IF;
    INSERT INTO milestones (contract_id, title, amount, due_date)
    VALUES (p_contract, p_title, p_amount, p_due);
    COMMIT;
END$$

CREATE PROCEDURE sp_record_payment (IN p_actor INT, IN p_milestone INT, IN p_method VARCHAR(50), IN p_status VARCHAR(20))
SQL SECURITY DEFINER
BEGIN
    DECLARE v_client INT;
    DECLARE v_freelancer INT;
    DECLARE v_amount DECIMAL(15,2);
    DECLARE v_contract INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    IF SUBSTRING_INDEX(USER(), '@', 1) <> 'payment_service' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only trusted payment service records payment results';
    END IF;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;
    SELECT contract_id INTO v_contract FROM milestones WHERE milestone_id = p_milestone;
    SELECT client_id, freelancer_id INTO v_client, v_freelancer
    FROM contracts WHERE contract_id = v_contract FOR UPDATE;
    SELECT amount INTO v_amount FROM milestones WHERE milestone_id = p_milestone FOR UPDATE;
    IF p_actor IS NULL OR v_client IS NULL OR v_client <> p_actor THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payer is not owning client';
    END IF;
    INSERT INTO payments (milestone_id, payer_id, payee_id, amount, payment_method, payment_status)
    VALUES (p_milestone, v_client, v_freelancer, v_amount, p_method, p_status);
    COMMIT;
END$$
DELIMITER ;


-- File: 05_seed.sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
USE mini_upwork;
START TRANSACTION;
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (1, 'demo1@example.test', 'Demo user 1', 'DEMO_HASH_NOT_FOR_LOGIN', 'CLIENT');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (2, 'demo2@example.test', 'Demo user 2', 'DEMO_HASH_NOT_FOR_LOGIN', 'CLIENT');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (3, 'demo3@example.test', 'Demo user 3', 'DEMO_HASH_NOT_FOR_LOGIN', 'CLIENT');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (4, 'demo4@example.test', 'Demo user 4', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (5, 'demo5@example.test', 'Demo user 5', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (6, 'demo6@example.test', 'Demo user 6', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (7, 'demo7@example.test', 'Demo user 7', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (8, 'demo8@example.test', 'Demo user 8', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
UPDATE clients SET company_name = CONCAT('Demo studio ', client_id);
UPDATE freelancers SET professional_title = 'Database and software specialist', hourly_rate = 25 + freelancer_id;
INSERT INTO skills (skill_name) VALUES ('SQL'), ('Python'), ('Design'), ('Java'), ('Testing'), ('Analytics');
INSERT INTO job_categories (category_name) VALUES ('Software'), ('Design'), ('Data');
INSERT INTO freelancer_skills VALUES (4,1,'EXPERT'),(4,2,'ADVANCED'),(4,5,'ADVANCED'),(5,3,'EXPERT'),(5,5,'INTERMEDIATE'),(6,1,'ADVANCED'),(6,2,'ADVANCED'),(6,6,'EXPERT'),(7,4,'ADVANCED'),(8,1,'INTERMEDIATE');
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (1,1,1,'Demo job 1','Synthetic project scope',500,1000,'2026-09-01','2027-02-01');
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (2,1,2,'Demo job 2','Synthetic project scope',400,800,'2026-09-01','2027-02-01');
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (3,2,3,'Demo job 3','Synthetic project scope',750,1500,'2026-09-01','2027-02-01');
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (4,2,1,'Demo job 4','Synthetic project scope',300,600,'2026-09-01','2027-02-01');
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (5,3,1,'Demo job 5','Synthetic project scope',1000,2000,'2026-09-01','2027-02-01');
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (6,3,3,'Demo job 6','Synthetic project scope',450,900,'2026-09-01','2027-02-01');
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (7,1,2,'Demo job 7','Synthetic project scope',250,500,'2026-09-01','2027-02-01');
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (8,2,3,'Demo job 8','Synthetic project scope',600,1200,'2026-09-01','2027-02-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (1,1,4,1000,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (2,1,6,950,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (3,2,5,800,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (4,2,4,750,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (5,3,6,1500,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (6,3,8,1400,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (7,4,7,600,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (8,5,4,2000,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (9,5,7,1900,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (10,6,6,900,'Synthetic proposal',60,'2026-10-01');
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (11,8,8,1200,'Synthetic proposal',60,'2026-10-01');
UPDATE proposals SET status = 'CLIENT_ACCEPTED' WHERE proposal_id = 1;
UPDATE proposals SET status = 'CONFIRMED' WHERE proposal_id = 1;
UPDATE proposals SET status = 'CLIENT_ACCEPTED' WHERE proposal_id = 3;
UPDATE proposals SET status = 'CONFIRMED' WHERE proposal_id = 3;
UPDATE proposals SET status = 'CLIENT_ACCEPTED' WHERE proposal_id = 5;
UPDATE proposals SET status = 'CONFIRMED' WHERE proposal_id = 5;
UPDATE proposals SET status = 'CLIENT_ACCEPTED' WHERE proposal_id = 7;
UPDATE proposals SET status = 'CONFIRMED' WHERE proposal_id = 7;
UPDATE proposals SET status = 'CLIENT_ACCEPTED' WHERE proposal_id = 8;
UPDATE proposals SET status = 'CONFIRMED' WHERE proposal_id = 8;
UPDATE proposals SET status = 'CLIENT_ACCEPTED' WHERE proposal_id = 10;
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (1,1,'Deliverable 1',400,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (2,1,'Deliverable 2',600,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (3,2,'Deliverable 3',300,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (4,2,'Deliverable 4',500,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (5,3,'Deliverable 5',500,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (6,3,'Deliverable 6',1000,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (7,4,'Deliverable 7',200,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (8,4,'Deliverable 8',400,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (9,5,'Deliverable 9',500,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (10,5,'Deliverable 10',1500,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
UPDATE milestones SET status='IN_PROGRESS' WHERE milestone_id=1;
UPDATE milestones SET status='COMPLETED' WHERE milestone_id=1;
UPDATE milestones SET status='IN_PROGRESS' WHERE milestone_id=2;
UPDATE milestones SET status='COMPLETED' WHERE milestone_id=2;
UPDATE milestones SET status='IN_PROGRESS' WHERE milestone_id=3;
UPDATE milestones SET status='COMPLETED' WHERE milestone_id=3;
UPDATE milestones SET status='IN_PROGRESS' WHERE milestone_id=5;
UPDATE milestones SET status='COMPLETED' WHERE milestone_id=5;
UPDATE milestones SET status='IN_PROGRESS' WHERE milestone_id=7;
UPDATE milestones SET status='COMPLETED' WHERE milestone_id=7;
UPDATE milestones SET status='IN_PROGRESS' WHERE milestone_id=9;
UPDATE milestones SET status='COMPLETED' WHERE milestone_id=9;
UPDATE milestones SET status='APPROVED' WHERE milestone_id=1;
UPDATE milestones SET status='APPROVED' WHERE milestone_id=3;
UPDATE milestones SET status='APPROVED' WHERE milestone_id=5;
UPDATE milestones SET status='APPROVED' WHERE milestone_id=7;
UPDATE milestones SET status='APPROVED' WHERE milestone_id=9;
INSERT INTO payments (payment_id,milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (1,1,1,4,400,'BANK_TRANSFER','FAILED');
INSERT INTO payments (payment_id,milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (2,1,1,4,400,'BANK_TRANSFER','PAID');
INSERT INTO payments (payment_id,milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (3,3,1,5,300,'BANK_TRANSFER','PAID');
INSERT INTO payments (payment_id,milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (4,5,2,6,500,'BANK_TRANSFER','PENDING');
INSERT INTO payments (payment_id,milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (5,7,2,7,200,'BANK_TRANSFER','PAID');
INSERT INTO payments (payment_id,milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (6,9,3,4,500,'BANK_TRANSFER','FAILED');
COMMIT;


-- File: 08_seed_1000_jobs.sql
-- Extension to 05_seed.sql. Run once as the installer/DBA, in a standalone session.
-- Adds 1,000 jobs and a connected synthetic workflow. No constraints are disabled.
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
USE mini_upwork;
DROP PROCEDURE IF EXISTS seed_g3_large_fixture;
DELIMITER $$
CREATE PROCEDURE seed_g3_large_fixture()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE k INT;
    DECLARE v_client INT;
    DECLARE v_freelancer INT;
    DECLARE v_job INT;
    DECLARE v_proposal INT;
    DECLARE v_contract INT;
    DECLARE v_milestone INT;
    DECLARE v_mode INT;
    DECLARE v_amount DECIMAL(15,2);
    DECLARE v_title VARCHAR(100);
    DECLARE v_method VARCHAR(50);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    IF (SELECT COUNT(*) FROM users WHERE user_id BETWEEN 1 AND 8) <> 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Install 01 through 05 before the large fixture';
    END IF;
    IF EXISTS (SELECT 1 FROM users WHERE user_id >= 20000)
       OR EXISTS (SELECT 1 FROM jobs WHERE job_id >= 22000)
       OR EXISTS (SELECT 1 FROM skills WHERE skill_id >= 20000)
       OR EXISTS (SELECT 1 FROM job_categories WHERE category_id >= 20000) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Large fixture ID ranges occupied; refusing duplicate import';
    END IF;

    WHILE i <= 40 DO
        INSERT INTO users (user_id, email, full_name, password_hash, user_type)
        VALUES (20000 + i, CONCAT('client', i, '@synthetic.example.test'),
                CONCAT('Synthetic Client ', i), 'DEMO_HASH_NOT_FOR_LOGIN', 'CLIENT');
        UPDATE clients SET company_name = CONCAT('Synthetic Studio ', i),
            company_description = 'Fictional company for coursework demonstration',
            location = ELT(1 + MOD(i, 3), 'Ha Noi', 'Da Nang', 'Ho Chi Minh City')
        WHERE client_id = 20000 + i;
        SET i = i + 1;
    END WHILE;

    SET i = 1;
    WHILE i <= 200 DO
        INSERT INTO users (user_id, email, full_name, password_hash, user_type)
        VALUES (21000 + i, CONCAT('freelancer', i, '@synthetic.example.test'),
                CONCAT('Synthetic Freelancer ', i), 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
        UPDATE freelancers SET professional_title = ELT(1 + MOD(i, 4),
            'Web Developer', 'Data Engineer', 'Product Designer', 'QA Engineer'),
            bio = 'Fictional professional profile for coursework', hourly_rate = 15 + MOD(i, 66),
            experience_level = ELT(1 + MOD(i, 4), 'BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')
        WHERE freelancer_id = 21000 + i;
        SET i = i + 1;
    END WHILE;

    SET i = 1;
    WHILE i <= 20 DO
        INSERT INTO skills (skill_id, skill_name) VALUES (20000 + i,
            ELT(i, 'JavaScript', 'TypeScript', 'React', 'Vue', 'Angular', 'Node.js',
                'PHP', 'Laravel', 'CSharp', 'DotNet', 'Go', 'Rust', 'Docker',
                'Kubernetes', 'AWS', 'Figma', 'UX Research', 'Power BI', 'Tableau', 'Selenium'));
        SET i = i + 1;
    END WHILE;
    SET i = 1;
    WHILE i <= 200 DO
        SET k = 0;
        WHILE k < 3 DO
            INSERT INTO freelancer_skills (freelancer_id, skill_id, skill_level)
            VALUES (21000 + i, 20001 + MOD(i + k, 20),
                    ELT(1 + MOD(i + k, 4), 'BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT'));
            SET k = k + 1;
        END WHILE;
        SET i = i + 1;
    END WHILE;

    SET i = 1;
    WHILE i <= 8 DO
        INSERT INTO job_categories (category_id, category_name, description)
        VALUES (20000 + i, ELT(i, 'Web Development', 'Mobile Applications', 'Data Engineering',
            'Business Intelligence', 'Product Design', 'Quality Assurance', 'Cloud Engineering',
            'Technical Writing'), 'Synthetic marketplace category');
        SET i = i + 1;
    END WHILE;

    SET i = 1;
    WHILE i <= 1000 DO
        SET v_client = 20001 + MOD(i - 1, 40);
        SET v_freelancer = 21001 + MOD(i - 1, 200);
        SET v_job = 22000 + i;
        SET v_proposal = 23000 + 2 * i - 1;
        SET v_amount = 900 + 30 * MOD(i, 40);
        SET v_title = ELT(1 + MOD(i - 1, 8), 'Company website', 'Mobile booking app',
            'Data pipeline', 'Sales dashboard', 'Product interface', 'Regression test suite',
            'Cloud deployment', 'Technical documentation');
        INSERT INTO jobs (job_id, client_id, category_id, title, description,
                          budget_min, budget_max, created_at, deadline)
        VALUES (v_job, v_client, 20001 + MOD(i - 1, 8), CONCAT(v_title, ' project ', i),
                'Synthetic fixed-price assignment with three planned deliverables',
                v_amount * 0.5, v_amount, DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY),
                DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY));

        -- The last 100 jobs deliberately have no proposal, supporting NOT EXISTS reports.
        IF i <= 900 THEN
            INSERT INTO proposals (proposal_id, job_id, freelancer_id, proposed_amount,
                                   cover_letter, estimated_days, submitted_at)
            VALUES (v_proposal, v_job, v_freelancer, v_amount,
                    'Synthetic proposal covering requirements, delivery and verification',
                    60, DATE_SUB(CURRENT_DATE, INTERVAL 10 DAY));
            INSERT INTO proposals (proposal_id, job_id, freelancer_id, proposed_amount,
                                   cover_letter, estimated_days, submitted_at)
            VALUES (v_proposal + 1, v_job, 21001 + MOD(i + 16, 200), v_amount - 30,
                    'Synthetic alternative proposal', 60, DATE_SUB(CURRENT_DATE, INTERVAL 9 DAY));
        END IF;

        IF i <= 600 THEN
            UPDATE proposals SET status = 'CLIENT_ACCEPTED' WHERE proposal_id = v_proposal;
            UPDATE proposals SET status = 'CONFIRMED' WHERE proposal_id = v_proposal;
            -- Read the trigger-created contract ID; do not assume its AUTO_INCREMENT value.
            SELECT contract_id INTO v_contract FROM contracts WHERE proposal_id = v_proposal;
            UPDATE proposals SET status = 'REJECTED' WHERE proposal_id = v_proposal + 1;
            SET v_mode = MOD(i, 5);
            SET k = 1;
            WHILE k <= 3 DO
                SET v_milestone = 26000 + (i - 1) * 3 + k;
                SET v_method = ELT(1 + MOD(i + k, 3), 'PAYPAL', 'CREDIT_CARD', 'BANK_TRANSFER');
                INSERT INTO milestones (milestone_id, contract_id, title, description, amount, due_date)
                VALUES (v_milestone, v_contract, CONCAT('Deliverable ', k, ' for project ', i),
                        ELT(k, 'Requirements and prototype', 'Implementation', 'Verification and handover'),
                        v_amount / 3, DATE_ADD(CURRENT_DATE, INTERVAL (k * 15) DAY));
                IF v_mode = 0 OR k = 1 OR (v_mode = 1 AND k = 2) THEN
                    UPDATE milestones SET status = 'IN_PROGRESS' WHERE milestone_id = v_milestone;
                    UPDATE milestones SET status = 'COMPLETED' WHERE milestone_id = v_milestone;
                ELSEIF v_mode = 4 AND k = 3 THEN
                    UPDATE milestones SET status = 'IN_PROGRESS' WHERE milestone_id = v_milestone;
                END IF;
                IF v_mode = 0 OR (k = 1 AND v_mode <> 4) THEN
                    UPDATE milestones SET status = 'APPROVED' WHERE milestone_id = v_milestone;
                    IF v_mode = 1 THEN
                        INSERT INTO payments (milestone_id, payer_id, payee_id, amount, payment_method, payment_status)
                        VALUES (v_milestone, v_client, v_freelancer, v_amount / 3, v_method, 'FAILED');
                    END IF;
                    INSERT INTO payments (milestone_id, payer_id, payee_id, amount, payment_method, payment_status)
                    VALUES (v_milestone, v_client, v_freelancer, v_amount / 3, v_method,
                            CASE v_mode WHEN 2 THEN 'PENDING' WHEN 3 THEN 'FAILED' ELSE 'PAID' END);
                END IF;
                SET k = k + 1;
            END WHILE;
            IF v_mode = 0 THEN
                UPDATE contracts SET status = 'COMPLETED' WHERE contract_id = v_contract;
                UPDATE jobs SET status = 'COMPLETED' WHERE job_id = v_job;
            END IF;
        ELSEIF i <= 700 THEN
            UPDATE proposals SET status = 'CLIENT_ACCEPTED' WHERE proposal_id = v_proposal;
        END IF;
        SET i = i + 1;
    END WHILE;
    COMMIT;
END$$
DELIMITER ;
CALL seed_g3_large_fixture();
DROP PROCEDURE seed_g3_large_fixture;


-- File: 07_security.sql
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


-- File: 09_verify_counts.sql
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

