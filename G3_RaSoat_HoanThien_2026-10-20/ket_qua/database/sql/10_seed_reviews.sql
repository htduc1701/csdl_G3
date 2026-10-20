USE mini_upwork;
-- DBA seed: close only fully allocated, approved, paid contracts; no trigger bypass.
UPDATE contracts AS c SET status='COMPLETED'
WHERE c.status='ACTIVE'
  AND c.total_amount=(SELECT SUM(m.amount) FROM milestones AS m WHERE m.contract_id=c.contract_id)
  AND NOT EXISTS (SELECT 1 FROM milestones AS m WHERE m.contract_id=c.contract_id
    AND (m.status<>'APPROVED' OR NOT EXISTS (SELECT 1 FROM payments AS p
      WHERE p.milestone_id=m.milestone_id AND p.payment_status='PAID')));
DELIMITER $$
CREATE PROCEDURE seed_g3_reviews()
BEGIN
    DECLARE v_id INT;
    DECLARE v_done BOOLEAN DEFAULT FALSE;
    DECLARE review_contracts CURSOR FOR SELECT contract_id FROM contracts WHERE status='COMPLETED';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=TRUE;
    OPEN review_contracts;
    review_loop: LOOP
        FETCH review_contracts INTO v_id;
        IF v_done THEN LEAVE review_loop; END IF;
        INSERT INTO contract_reviews(contract_id,rating,review_text)
        VALUES(v_id,3+MOD(v_id,3),'Fictional review for the database coursework');
    END LOOP;
    CLOSE review_contracts;
END$$
DELIMITER ;
CALL seed_g3_reviews();
DROP PROCEDURE seed_g3_reviews;
