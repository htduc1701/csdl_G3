# Trigger catalog

SQL below is identical to02_triggers.sql. Tests are executable in tests/run_tests.py and fully recorded in docs/test_report.md. Some history/identity triggers intentionally reject every DELETE; their positive control is valid retention/update, not a fabricated successful deletion. Parent aggregate guards require READ COMMITTED and statement-safe VALUES/procedure writes. Application roles cannot issue table DML. Trigger definer requires controlled DBA provisioning.

## tr_users_create_subtype

Creates exactly one matching subtype in the same user insert statement; a failure rolls back both.

Positive control: TP-01. Negative control: TC-04.

```sql
CREATE TRIGGER tr_users_create_subtype
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.user_type = 'CLIENT' THEN
        INSERT INTO clients (client_id) VALUES (NEW.user_id);
    ELSE
        INSERT INTO freelancers (freelancer_id) VALUES (NEW.user_id);
    END IF;
END;
```

## tr_users_identity_immutable

Keeps user_id and user_type fixed while profile information can change.

Positive control: TP-12. Negative control: TC-23.

```sql
CREATE TRIGGER tr_users_identity_immutable
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.user_id <> OLD.user_id OR NEW.user_type <> OLD.user_type THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 user identity and subtype are immutable';
    END IF;
END;
```

## tr_clients_type

Checks subtype parent discriminator; user registration already owns the inserted parent row.

Positive control: TP-01. Negative control: TC-49.

```sql
CREATE TRIGGER tr_clients_type
BEFORE INSERT ON clients
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(20);
    SELECT user_type INTO v_type FROM users WHERE user_id = NEW.client_id;
    IF v_type IS NULL OR v_type <> 'CLIENT' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 subtype must match parent user_type';
    END IF;
END;
```

## tr_clients_identity

Client ID updates are forbidden; profile edits allowed.

Positive control: TP-10. Negative control: TC-48.

```sql
CREATE TRIGGER tr_clients_identity
BEFORE UPDATE ON clients
FOR EACH ROW
BEGIN
    IF NEW.client_id <> OLD.client_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 subtype identity is immutable';
    END IF;
END;
```

## tr_clients_retain

No DELETE is valid; positive control edits an existing retained profile.

Positive control: TP-10. Negative control: TC-24.

```sql
CREATE TRIGGER tr_clients_retain
BEFORE DELETE ON clients
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 total specialization requires subtype retention';
END;
```

## tr_freelancers_type

Rejects a freelancer row under a CLIENT parent.

Positive control: TP-01. Negative control: TC-01.

```sql
CREATE TRIGGER tr_freelancers_type
BEFORE INSERT ON freelancers
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(20);
    SELECT user_type INTO v_type FROM users WHERE user_id = NEW.freelancer_id;
    IF v_type IS NULL OR v_type <> 'FREELANCER' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 subtype must match parent user_type';
    END IF;
END;
```

## tr_freelancers_identity

Allows profile edits but not re-parenting.

Positive control: TP-11. Negative control: TC-41.

```sql
CREATE TRIGGER tr_freelancers_identity
BEFORE UPDATE ON freelancers
FOR EACH ROW
BEGIN
    IF NEW.freelancer_id <> OLD.freelancer_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 subtype identity is immutable';
    END IF;
END;
```

## tr_freelancers_retain

No DELETE is valid; positive control preserves/edits subtype.

Positive control: TP-11. Negative control: TC-42.

```sql
CREATE TRIGGER tr_freelancers_retain
BEFORE DELETE ON freelancers
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-02 total specialization requires subtype retention';
END;
```

## tr_jobs_owner

Owner/creation identity cannot change after proposal/contract association.

Positive control: TP-13. Negative control: TC-30.

```sql
CREATE TRIGGER tr_jobs_owner
BEFORE UPDATE ON jobs
FOR EACH ROW
BEGIN
    IF NEW.job_id <> OLD.job_id OR NEW.client_id <> OLD.client_id OR NEW.created_at <> OLD.created_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job owner identity and creation time are immutable';
    END IF;
END;
```

## tr_proposals_initial

Only OPEN job and initial PENDING proposal.

Positive control: TP-02. Negative control: TC-45.

```sql
CREATE TRIGGER tr_proposals_initial
BEFORE INSERT ON proposals
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM jobs WHERE job_id = NEW.job_id FOR UPDATE;
    IF v_status IS NULL OR v_status <> 'OPEN' OR NEW.status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proposal requires OPEN job and initial PENDING status';
    END IF;
END;
```

## tr_proposals_transition

Two consent steps in order, immutable selected terms and associations.

Positive control: TP-04. Negative control: TC-14.

```sql
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
END;
```

## tr_contracts_validate

Requires confirmed proposal and matching participants/initial amount.

Positive control: TP-04. Negative control: TC-46.

```sql
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
END;
```

## tr_proposals_create_contract

Confirmation automatically inserts contract and marks job IN_PROGRESS; one atomic SQL statement.

Positive control: TP-04. Negative control: TC-14.

```sql
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
END;
```

## tr_contracts_update

Rechecks allocation/date bounds and paid completion before contract changes.

Positive control: TP-09. Negative control: TC-22.

```sql
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
END;
```

## tr_milestones_insert

Locks parent then sums amounts; rejects total overflow.

Positive control: TP-03. Negative control: TC-03.

```sql
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
END;
```

## tr_milestones_update

Excludes OLD milestone from aggregate before adding NEW; protects state and immutable started terms.

Positive control: TP-08. Negative control: TC-21.

```sql
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
END;
```

## tr_milestones_delete

No DELETE is valid; retained history supports completion.

Positive control: TP-09. Negative control: TC-43.

```sql
CREATE TRIGGER tr_milestones_delete
BEFORE DELETE ON milestones
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Milestones retained for work and financial audit';
END;
```

## tr_payments_insert

Locks work/contract, validates approval, payer/payee and amount.

Positive control: TP-05. Negative control: TC-15.

```sql
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

END;
```

## tr_payments_update

PENDING may transition to PAID or FAILED; terminal evidence is immutable.

Positive control: TP-07. Negative control: TC-27.

```sql
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

END;
```

## tr_payments_delete

No DELETE is valid; retained failed attempt supports retry evidence.

Positive control: TP-06. Negative control: TC-29.

```sql
CREATE TRIGGER tr_payments_delete
BEFORE DELETE ON payments
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment evidence cannot be deleted';
END;
```

## tr_contracts_retain

No DELETE is valid, preserves exactly one contract for each confirmed proposal.

Positive control: TP-04. Negative control: TC-44.

```sql
CREATE TRIGGER tr_contracts_retain
BEFORE DELETE ON contracts
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BR-11 confirmed contract must be retained';
END;
```
