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
