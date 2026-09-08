-- =============================================================================
-- SYSTEM: FREELANCE MARKETPLACE ECOSYSTEM (MINI-UPWORK)
-- SECTION: 4.1 DATABASE IMPLEMENTATION - DDL SCRIPT
-- COMPLIANCY: SQLStyle.guide / Google SQL Style Guide / ISO/IEC 11179
-- DESIGNED BY: TEAM G3 (Huynh Thien Duc, Pham Viet Hoang, Dang Quang Huy)
-- =============================================================================

-- CREATE DATABASE (Optional/Default setup)
-- CREATE DATABASE IF NOT EXISTS freelance_marketplace;
-- USE freelance_marketplace;

-- =============================================================================
-- 1. DROP TABLES (Ordered to respect foreign key constraints)
-- =============================================================================
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS milestones;
DROP TABLE IF EXISTS contracts;
DROP TABLE IF EXISTS proposals;
DROP TABLE IF EXISTS jobs;
DROP TABLE IF EXISTS job_categories;
DROP TABLE IF EXISTS freelancer_skills;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS freelancers;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS users;

-- =============================================================================
-- 2. CREATE TABLES & BASE CONSTRAINTS (ISO/IEC 11179 Aligned)
-- =============================================================================

-- 2.1 USER TABLE (Supertype)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT,
    email VARCHAR(150) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    
    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.2 CLIENT TABLE (Subtype - 1:1 Specialization)
CREATE TABLE clients (
    client_id INT NOT NULL,
    company_name VARCHAR(150) DEFAULT NULL,
    company_description TEXT DEFAULT NULL,
    location VARCHAR(150) DEFAULT NULL,
    
    CONSTRAINT pk_clients PRIMARY KEY (client_id),
    CONSTRAINT fk_clients_users FOREIGN KEY (client_id) 
        REFERENCES users (user_id) 
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.3 FREELANCER TABLE (Subtype - 1:1 Specialization)
CREATE TABLE freelancers (
    freelancer_id INT NOT NULL,
    professional_title VARCHAR(150) NOT NULL,
    bio TEXT DEFAULT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    experience_level VARCHAR(20) NOT NULL DEFAULT 'INTERMEDIATE',
    
    CONSTRAINT pk_freelancers PRIMARY KEY (freelancer_id),
    CONSTRAINT fk_freelancers_users FOREIGN KEY (freelancer_id) 
        REFERENCES users (user_id) 
        ON DELETE CASCADE,
    CONSTRAINT chk_freelancers_hourly_rate CHECK (hourly_rate >= 0.00),
    CONSTRAINT chk_freelancers_experience_level CHECK (experience_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.4 SKILL TABLE
CREATE TABLE skills (
    skill_id INT AUTO_INCREMENT,
    skill_name VARCHAR(100) NOT NULL,
    
    CONSTRAINT pk_skills PRIMARY KEY (skill_id),
    CONSTRAINT uq_skills_skill_name UNIQUE (skill_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.5 FREELANCER_SKILL TABLE (M:N Associative Table)
CREATE TABLE freelancer_skills (
    freelancer_id INT NOT NULL,
    skill_id INT NOT NULL,
    skill_level VARCHAR(20) NOT NULL DEFAULT 'INTERMEDIATE',
    
    CONSTRAINT pk_freelancer_skills PRIMARY KEY (freelancer_id, skill_id),
    CONSTRAINT fk_freelancer_skills_freelancers FOREIGN KEY (freelancer_id) 
        REFERENCES freelancers (freelancer_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_freelancer_skills_skills FOREIGN KEY (skill_id) 
        REFERENCES skills (skill_id) 
        ON DELETE CASCADE,
    CONSTRAINT chk_freelancer_skills_level CHECK (skill_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.6 JOB_CATEGORY TABLE
CREATE TABLE job_categories (
    category_id INT AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL,
    description TEXT DEFAULT NULL,
    
    CONSTRAINT pk_job_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_job_categories_name UNIQUE (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.7 JOB TABLE
CREATE TABLE jobs (
    job_id INT AUTO_INCREMENT,
    client_id INT NOT NULL,
    category_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    budget_min DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    budget_max DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    deadline DATE DEFAULT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    
    CONSTRAINT pk_jobs PRIMARY KEY (job_id),
    CONSTRAINT fk_jobs_clients FOREIGN KEY (client_id) 
        REFERENCES clients (client_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_jobs_categories FOREIGN KEY (category_id) 
        REFERENCES job_categories (category_id) 
        ON DELETE CASCADE,
    CONSTRAINT chk_jobs_budget_min CHECK (budget_min >= 0.00),
    CONSTRAINT chk_jobs_budget_max CHECK (budget_max >= budget_min),
    CONSTRAINT chk_jobs_status CHECK (status IN ('OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.8 PROPOSAL TABLE
CREATE TABLE proposals (
    proposal_id INT AUTO_INCREMENT,
    job_id INT NOT NULL,
    freelancer_id INT NOT NULL,
    proposed_amount DECIMAL(15,2) NOT NULL,
    cover_letter TEXT NOT NULL,
    estimated_days INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_proposals PRIMARY KEY (proposal_id),
    CONSTRAINT fk_proposals_jobs FOREIGN KEY (job_id) 
        REFERENCES jobs (job_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_proposals_freelancers FOREIGN KEY (freelancer_id) 
        REFERENCES freelancers (freelancer_id) 
        ON DELETE CASCADE,
    CONSTRAINT uq_proposals_job_freelancer UNIQUE (job_id, freelancer_id), -- BR-08: Max 1 proposal per job per freelancer
    CONSTRAINT chk_proposals_proposed_amount CHECK (proposed_amount > 0.00),
    CONSTRAINT chk_proposals_estimated_days CHECK (estimated_days > 0),
    CONSTRAINT chk_proposals_status CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.9 CONTRACT TABLE
CREATE TABLE contracts (
    contract_id INT AUTO_INCREMENT,
    proposal_id INT NOT NULL,
    client_id INT NOT NULL,
    freelancer_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE DEFAULT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    
    CONSTRAINT pk_contracts PRIMARY KEY (contract_id),
    CONSTRAINT fk_contracts_proposals FOREIGN KEY (proposal_id) 
        REFERENCES proposals (proposal_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_contracts_clients FOREIGN KEY (client_id) 
        REFERENCES clients (client_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_contracts_freelancers FOREIGN KEY (freelancer_id) 
        REFERENCES freelancers (freelancer_id) 
        ON DELETE RESTRICT,
    CONSTRAINT uq_contracts_proposal UNIQUE (proposal_id), -- BR-11: 1 accepted proposal creates at most 1 contract
    CONSTRAINT chk_contracts_dates CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT chk_contracts_total_amount CHECK (total_amount > 0.00),
    CONSTRAINT chk_contracts_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.10 MILESTONE TABLE
CREATE TABLE milestones (
    milestone_id INT AUTO_INCREMENT,
    contract_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT DEFAULT NULL,
    amount DECIMAL(15,2) NOT NULL,
    due_date DATE DEFAULT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    
    CONSTRAINT pk_milestones PRIMARY KEY (milestone_id),
    CONSTRAINT fk_milestones_contracts FOREIGN KEY (contract_id) 
        REFERENCES contracts (contract_id) 
        ON DELETE CASCADE,
    CONSTRAINT chk_milestones_amount CHECK (amount > 0.00),
    CONSTRAINT chk_milestones_status CHECK (status IN ('PENDING', 'APPROVED', 'COMPLETED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.11 PAYMENT TABLE
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT,
    milestone_id INT NOT NULL,
    payer_id INT NOT NULL,
    payee_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT fk_payments_milestones FOREIGN KEY (milestone_id) 
        REFERENCES milestones (milestone_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_payments_payer FOREIGN KEY (payer_id) 
        REFERENCES users (user_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_payments_payee FOREIGN KEY (payee_id) 
        REFERENCES users (user_id) 
        ON DELETE RESTRICT,
    CONSTRAINT uq_payments_milestone UNIQUE (milestone_id), -- BR-16: At most 1 successful payment per milestone
    CONSTRAINT chk_payments_amount CHECK (amount > 0.00),
    CONSTRAINT chk_payments_status CHECK (payment_status IN ('PENDING', 'PAID', 'FAILED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.12 REVIEW TABLE
CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT,
    contract_id INT NOT NULL,
    reviewer_id INT NOT NULL,
    reviewee_id INT NOT NULL,
    rating INT NOT NULL,
    comment TEXT DEFAULT NULL,
    
    CONSTRAINT pk_reviews PRIMARY KEY (review_id),
    CONSTRAINT fk_reviews_contracts FOREIGN KEY (contract_id) 
        REFERENCES contracts (contract_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_reviews_reviewer FOREIGN KEY (reviewer_id) 
        REFERENCES users (user_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_reviews_reviewee FOREIGN KEY (reviewee_id) 
        REFERENCES users (user_id) 
        ON DELETE CASCADE,
    CONSTRAINT uq_reviews_contract_reviewer UNIQUE (contract_id, reviewer_id), -- BR-20: Max 1 review from each party per contract
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_reviews_no_self_review CHECK (reviewer_id <> reviewee_id) -- BR-18: Cannot review yourself
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================================
-- 3. VIEWS (To support business operations and dynamic reports)
-- =============================================================================

-- 3.1 VIEW: V_FREELANCER_RATINGS (Calculates derived Freelancer Average Ratings dynamically)
CREATE OR REPLACE VIEW v_freelancer_ratings AS
SELECT 
    f.freelancer_id,
    u.full_name AS freelancer_name,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.rating), 2) AS average_rating
FROM freelancers f
JOIN users u ON f.freelancer_id = u.user_id
LEFT JOIN reviews r ON f.freelancer_id = r.reviewee_id
GROUP BY f.freelancer_id, u.full_name;

-- 3.2 VIEW: V_ACTIVE_CONTRACTS_PROGRESS (Monitors Contract financial progress)
CREATE OR REPLACE VIEW v_active_contracts_progress AS
SELECT 
    c.contract_id,
    j.title AS job_title,
    cu.full_name AS client_name,
    fu.full_name AS freelancer_name,
    c.total_amount AS contract_value,
    COALESCE(SUM(m.amount), 0.00) AS allocated_milestone_amount,
    COALESCE(SUM(CASE WHEN p.payment_status = 'PAID' THEN p.amount ELSE 0.00 END), 0.00) AS total_paid_amount,
    c.status AS contract_status
FROM contracts c
JOIN jobs j ON c.contract_id = j.job_id
JOIN users cu ON c.client_id = cu.user_id
JOIN users fu ON c.freelancer_id = fu.user_id
LEFT JOIN milestones m ON c.contract_id = m.contract_id
LEFT JOIN payments p ON m.milestone_id = p.milestone_id
GROUP BY c.contract_id, j.title, cu.full_name, fu.full_name, c.total_amount, c.status;


-- =============================================================================
-- 4. PERFORMANCE INDEXES (Optimizing typical high-frequency searches)
-- =============================================================================

-- For Job Searching & Category filtering
CREATE INDEX idx_jobs_category_status ON jobs (category_id, status);
CREATE INDEX idx_jobs_budget ON jobs (budget_min, budget_max);

-- For Freelancer portfolio & Skills mapping
CREATE INDEX idx_freelancer_skills_skill ON freelancer_skills (skill_id);

-- For Contract lookup and status reports
CREATE INDEX idx_contracts_client ON contracts (client_id);
CREATE INDEX idx_contracts_freelancer ON contracts (freelancer_id);
CREATE INDEX idx_contracts_status ON contracts (status);


-- =============================================================================
-- 5. BUSINESS TRIGGERS (Enforcing advanced Business Rules)
-- =============================================================================

DELIMITER $$

-- 5.1 TRIGGER: ENFORCE DISJOINT SUBTYPES ON CLIENTS INSERT (BR-02)
CREATE TRIGGER trg_clients_disjoint_insert
BEFORE INSERT ON clients
FOR EACH ROW
BEGIN
    DECLARE freelancer_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO freelancer_exists
    FROM freelancers
    WHERE freelancer_id = NEW.client_id;
    
    IF freelancer_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Business Rule Violation (BR-02): A USER cannot be both a CLIENT and a FREELANCER (Disjoint).';
    END IF;
END$$

-- 5.2 TRIGGER: ENFORCE DISJOINT SUBTYPES ON FREELANCERS INSERT (BR-02)
CREATE TRIGGER trg_freelancers_disjoint_insert
BEFORE INSERT ON freelancers
FOR EACH ROW
BEGIN
    DECLARE client_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO client_exists
    FROM clients
    WHERE client_id = NEW.freelancer_id;
    
    IF client_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Business Rule Violation (BR-02): A USER cannot be both a CLIENT and a FREELANCER (Disjoint).';
    END IF;
END$$

-- 5.3 TRIGGER: ENFORCE TOTAL MILESTONES BUDGETS CANNOT EXCEED CONTRACT TOTAL ON INSERT (BR-14)
CREATE TRIGGER trg_milestones_budget_insert
BEFORE INSERT ON milestones
FOR EACH ROW
BEGIN
    DECLARE current_total_milestones DECIMAL(15,2) DEFAULT 0.00;
    DECLARE contract_value DECIMAL(15,2) DEFAULT 0.00;
    
    SELECT COALESCE(SUM(amount), 0.00) INTO current_total_milestones
    FROM milestones
    WHERE contract_id = NEW.contract_id;
    
    SELECT total_amount INTO contract_value
    FROM contracts
    WHERE contract_id = NEW.contract_id;
    
    IF (current_total_milestones + NEW.amount) > contract_value THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Business Rule Violation (BR-14): Total milestones budget cannot exceed Contract total amount.';
    END IF;
END$$

-- 5.4 TRIGGER: ENFORCE TOTAL MILESTONES BUDGETS CANNOT EXCEED CONTRACT TOTAL ON UPDATE (BR-14)
CREATE TRIGGER trg_milestones_budget_update
BEFORE UPDATE ON milestones
FOR EACH ROW
BEGIN
    DECLARE current_total_milestones DECIMAL(15,2) DEFAULT 0.00;
    DECLARE contract_value DECIMAL(15,2) DEFAULT 0.00;
    
    SELECT COALESCE(SUM(amount), 0.00) INTO current_total_milestones
    FROM milestones
    WHERE contract_id = NEW.contract_id AND milestone_id <> NEW.milestone_id;
    
    SELECT total_amount INTO contract_value
    FROM contracts
    WHERE contract_id = NEW.contract_id;
    
    IF (current_total_milestones + NEW.amount) > contract_value THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Business Rule Violation (BR-14): Total milestones budget cannot exceed Contract total amount.';
    END IF;
END$$

-- 5.5 TRIGGER: ENFORCE REVIEWER & REVIEWEE MUST BE PARTIES OF THE CONTRACT (BR-17)
CREATE TRIGGER trg_reviews_parties_check
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    DECLARE contract_client INT;
    DECLARE contract_freelancer INT;
    
    SELECT client_id, freelancer_id INTO contract_client, contract_freelancer
    FROM contracts
    WHERE contract_id = NEW.contract_id;
    
    IF NEW.reviewer_id NOT IN (contract_client, contract_freelancer) OR 
       NEW.reviewee_id NOT IN (contract_client, contract_freelancer) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Business Rule Violation (BR-17): Both reviewer and reviewee must be the active parties associated with this Contract.';
    END IF;
END$$

DELIMITER ;
