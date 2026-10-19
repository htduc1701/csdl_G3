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
