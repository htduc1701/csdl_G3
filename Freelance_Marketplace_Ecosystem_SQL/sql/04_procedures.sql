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
