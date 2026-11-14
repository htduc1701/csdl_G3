# Verification evidence

Executed on MySQL8.0.42. Errors1062=unique,1452=FK,3819=CHECK,1644=business SIGNAL,1142=table privilege denied,1370=procedure privilege denied. Negative tests PASS when the expected rejection occurs. Transactions roll back individually; concurrency fixtures commit on disposable test data. Seed is rebuilt before query assertions; RBAC operations are performed afterwards.

## TC-01

Rule: BR-02. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO freelancers (freelancer_id) VALUES (1);
```

(1644, 'BR-02 subtype must match parent user_type')

## TC-02

Rule: BR-08. Expected: 1062. Actual: 1062. Result: PASS

```sql
INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (6,6,900,'duplicate',30);
```

(1062, "Duplicate entry '6-6' for key 'proposals.uq_proposal_freelancer_job'")

## TC-03

Rule: BR-14. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO milestones (contract_id,title,amount) VALUES (1,'excess',1);
```

(1644, 'BR-14 milestone sum exceeds contract')

## TC-04

Rule: email. Expected: 1062. Actual: 1062. Result: PASS

```sql
INSERT INTO users (email,full_name,password_hash,user_type) VALUES ('DEMO1@example.test','Duplicate','DEMO','CLIENT');
```

(1062, "Duplicate entry 'DEMO1@example.test' for key 'users.uq_users_email'")

## TC-05

Rule: BR-04. Expected: 1452. Actual: 1452. Result: PASS

```sql
INSERT INTO jobs (client_id,category_id,title,description) VALUES (1,999,'invalid','scope');
```

(1452, 'Cannot add or update a child row: a foreign key constraint fails (`mini_upwork`.`jobs`, CONSTRAINT `fk_jobs_category` FOREIGN KEY (`category_id`) REFERENCES `job_categories` (`category_id`))')

## TC-06

Rule: positive money. Expected: 3819. Actual: 3819. Result: PASS

```sql
INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (7,4,0,'invalid',10);
```

(3819, "Check constraint 'ck_proposal_amount' is violated.")

## TC-07

Rule: dates. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO contracts (proposal_id,client_id,freelancer_id,start_date,end_date,total_amount) VALUES (10,3,6,'2026-10-10','2026-10-09',900);
```

(1644, 'BR-11 requires confirmed proposal')

## TC-08

Rule: dates. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE contracts SET end_date = DATE_SUB(start_date,INTERVAL 1 DAY) WHERE contract_id=1;
```

(1644, 'BR-14 contract update invalidates milestones')

## TC-09

Rule: BR-11. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO contracts (proposal_id,client_id,freelancer_id,start_date,total_amount) VALUES (10,3,6,CURRENT_DATE,900);
```

(1644, 'BR-11 requires confirmed proposal')

## TC-10

Rule: BR-10. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE proposal_id=11;
```

accepted

## TC-11

Rule: BR-10. Expected: 1062. Actual: 1062. Result: PASS

```sql
UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE proposal_id=11;
INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (8,4,1000,'other',30);
UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE job_id=8 AND freelancer_id=4;
```

(1062, "Duplicate entry '8' for key 'proposals.uq_selected_job'")

## TC-12

Rule: BR-12. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE contracts SET client_id=2 WHERE contract_id=1;
```

(1644, 'Contract identity and parties are immutable')

## TC-13

Rule: BR-12. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE contracts SET freelancer_id=6 WHERE contract_id=1;
```

(1644, 'Contract identity and parties are immutable')

## TC-14

Rule: BR-11. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=11;
```

(1644, 'BR-11 illegal proposal transition')

## TC-15

Rule: BR-15. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (2,1,4,600,'PAYPAL','PAID');
```

(1644, 'BR-15 payment requires APPROVED active work')

## TC-16

Rule: BR-16. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method) VALUES (9,1,4,500,'PAYPAL');
```

(1644, 'BR-16 payment parties or amount mismatch')

## TC-17

Rule: BR-16. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method) VALUES (9,3,6,500,'PAYPAL');
```

(1644, 'BR-16 payment parties or amount mismatch')

## TC-18

Rule: BR-16. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method) VALUES (9,3,4,499,'PAYPAL');
```

(1644, 'BR-16 payment parties or amount mismatch')

## TC-19

Rule: one PAID. Expected: 1062. Actual: 1062. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (1,1,4,400,'PAYPAL','PAID');
```

(1062, "Duplicate entry '1' for key 'payments.uq_paid_milestone'")

## TC-20

Rule: status. Expected: 3819. Actual: 3819. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'PAYPAL','REFUNDED');
```

(3819, "Check constraint 'ck_payment_status' is violated.")

## TC-21

Rule: BR-14 update. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE milestones SET amount=1501 WHERE milestone_id=10;
```

(1644, 'BR-14 milestone sum exceeds contract')

## TC-22

Rule: BR-14 contract decrease. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE contracts SET total_amount=999 WHERE contract_id=1;
```

(1644, 'BR-14 contract update invalidates milestones')

## TC-23

Rule: BR-02 type switch. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE users SET user_type='FREELANCER' WHERE user_id=1;
```

(1644, 'BR-02 user identity and subtype are immutable')

## TC-24

Rule: BR-02 total. Expected: 1644. Actual: 1644. Result: PASS

```sql
DELETE FROM clients WHERE client_id=3;
```

(1644, 'BR-02 total specialization requires subtype retention')

## TC-25

Rule: BR-15 skip approval. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE milestones SET status='APPROVED' WHERE milestone_id=10;
```

(1644, 'BR-15 illegal milestone transition')

## TC-26

Rule: BR-16 method. Expected: 3819. Actual: 3819. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method) VALUES (9,3,4,500,'CASH');
```

(3819, "Check constraint 'ck_payment_method' is violated.")

## TC-27

Rule: payment terminal. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE payments SET payment_status='FAILED' WHERE payment_id=2;
```

(1644, 'Terminal payment cannot change status')

## TC-28

Rule: BR-15 revoke approval. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE milestones SET status='COMPLETED' WHERE milestone_id=1;
```

(1644, 'BR-15 illegal milestone transition')

## TC-29

Rule: payment audit. Expected: 1644. Actual: 1644. Result: PASS

```sql
DELETE FROM payments WHERE payment_id=1;
```

(1644, 'Payment evidence cannot be deleted')

## TC-30

Rule: job owner. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE jobs SET client_id=2 WHERE job_id=1;
```

(1644, 'Job owner identity and creation time are immutable')

## TP-01

Rule: BR-02 valid registration. Expected: 0. Actual: 0. Result: PASS

```sql
INSERT INTO users (user_id,email,full_name,password_hash,user_type) VALUES (99,'new@example.test','Synthetic new','DEMO','FREELANCER');
```

accepted

## TP-02

Rule: BR-08 valid proposal. Expected: 0. Actual: 0. Result: PASS

```sql
INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days) VALUES (7,4,500,'valid',20);
```

accepted

## TP-03

Rule: BR-14 within budget. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=10;
SELECT contract_id INTO @new_contract FROM contracts WHERE proposal_id=10;
INSERT INTO milestones (contract_id,title,amount) VALUES (@new_contract,'within',900);
```

accepted

## TP-04

Rule: BR-11 atomic confirmation. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=10;
```

accepted

## TP-05

Rule: BR-15 and BR-16 successful payment. Expected: 0. Actual: 0. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'PAYPAL','PAID');
```

accepted

## TP-06

Rule: retry after FAILED. Expected: 0. Actual: 0. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'BANK_TRANSFER','FAILED');
```

accepted

## TP-07

Rule: pending becomes PAID. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE payments SET payment_status='PAID' WHERE payment_id=4;
```

accepted

## TP-08

Rule: work then approval. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE milestones SET status='APPROVED' WHERE milestone_id=2;
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (2,1,4,600,'CREDIT_CARD','PAID');
```

accepted

## TP-09

Rule: completion only after fully paid. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE milestones SET status='APPROVED' WHERE milestone_id=2;
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (2,1,4,600,'CREDIT_CARD','PAID');
UPDATE contracts SET status='COMPLETED' WHERE contract_id=1;
```

accepted

## TC-31

Rule: date CHECK isolated. Expected: 3819. Actual: 3819. Result: PASS

```sql
UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=10;
UPDATE contracts SET end_date=DATE_SUB(start_date,INTERVAL 1 DAY) WHERE proposal_id=10;
```

(3819, "Check constraint 'ck_contract_dates' is violated.")

## TC-32

Rule: negative milestone. Expected: 3819. Actual: 3819. Result: PASS

```sql
UPDATE milestones SET amount=-1 WHERE milestone_id=10;
```

(3819, "Check constraint 'ck_milestone_amount' is violated.")

## TC-33

Rule: contract positive. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE contracts SET total_amount=0 WHERE contract_id=1;
```

(1644, 'BR-14 contract update invalidates milestones')

## TC-34

Rule: deadline. Expected: 3819. Actual: 3819. Result: PASS

```sql
UPDATE jobs SET deadline='2026-08-31' WHERE job_id=7;
```

(3819, "Check constraint 'ck_jobs_dates' is violated.")

## TC-35

Rule: milestone due. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE milestones SET due_date='2020-01-01' WHERE milestone_id=10;
```

(1644, 'Milestone date outside contract')

## TC-36

Rule: proposal identity. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE proposals SET freelancer_id=5 WHERE proposal_id=10;
```

(1644, 'Proposal identity is immutable')

## TC-37

Rule: milestone parent. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE milestones SET contract_id=2 WHERE milestone_id=10;
```

(1644, 'Milestone identity is immutable')

## TC-38

Rule: payment update duplicate. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE payments SET payment_status='PAID' WHERE payment_id=1;
```

(1644, 'Terminal payment cannot change status')

## TC-39

Rule: payment amount immutable. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE payments SET amount=501 WHERE payment_id=6;
```

(1644, 'BR-16 payment parties or amount mismatch')

## TC-40

Rule: contract completion. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE contracts SET status='COMPLETED' WHERE contract_id=1;
```

(1644, 'Completion requires fully allocated paid milestones')

## TC-41

Rule: subtype identity. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE freelancers SET freelancer_id=99 WHERE freelancer_id=4;
```

(1644, 'BR-02 subtype identity is immutable')

## TC-42

Rule: subtype retention. Expected: 1644. Actual: 1644. Result: PASS

```sql
DELETE FROM freelancers WHERE freelancer_id=8;
```

(1644, 'BR-02 total specialization requires subtype retention')

## TC-43

Rule: milestone audit. Expected: 1644. Actual: 1644. Result: PASS

```sql
DELETE FROM milestones WHERE milestone_id=10;
```

(1644, 'Milestones retained for work and financial audit')

## TC-44

Rule: BR-11 retention. Expected: 1644. Actual: 1644. Result: PASS

```sql
DELETE FROM contracts WHERE contract_id=1;
```

(1644, 'BR-11 confirmed contract must be retained')

## TC-45

Rule: BR-11 initial offer. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO proposals (job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,status) VALUES (7,4,500,'invalid',20,'CONFIRMED');
```

(1644, 'Proposal requires OPEN job and initial PENDING status')

## TC-46

Rule: BR-12 insert mismatch. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO contracts (proposal_id,client_id,freelancer_id,start_date,total_amount) VALUES (1,2,4,CURRENT_DATE,1000);
```

(1644, 'BR-12 contract parties or terms mismatch')

## TP-10

Rule: client profile edit. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE clients SET company_name='Demo revised' WHERE client_id=1;
```

accepted

## TP-11

Rule: freelancer profile edit. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE freelancers SET bio='Synthetic profile revision' WHERE freelancer_id=4;
```

accepted

## TP-12

Rule: user edit. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE users SET full_name='Demo name revision' WHERE user_id=1;
```

accepted

## TC-48

Rule: client subtype identity. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE clients SET client_id=99 WHERE client_id=1;
```

(1644, 'BR-02 subtype identity is immutable')

## TC-49

Rule: client wrong subtype. Expected: 1644. Actual: 1644. Result: PASS

```sql
INSERT INTO clients (client_id) VALUES (4);
```

(1644, 'BR-02 subtype must match parent user_type')

## TP-13

Rule: job mutable scope. Expected: 0. Actual: 0. Result: PASS

```sql
UPDATE jobs SET title='Demo revised scope' WHERE job_id=7;
```

accepted

## TC-47

Rule: unsupported isolation. Expected: 1644. Actual: 1644. Result: PASS

```sql
UPDATE milestones SET title='revised' WHERE milestone_id=10;
```

(1644, 'Milestone budget writes require READ COMMITTED')

## CC-01

Rule: concurrent gate. Expected: second waits then rejects; no invariant violation. Actual: {'error': 1644, 'message': "(1644, 'BR-14 milestone sum exceeds contract')"}. Result: PASS

```sql
UPDATE milestones SET amount=1400 WHERE milestone_id=10;
UPDATE milestones SET amount=1601 WHERE milestone_id=10;
```

{'error': 1644, 'message': "(1644, 'BR-14 milestone sum exceeds contract')"}

## CC-02

Rule: concurrent gate. Expected: second waits then rejects; no invariant violation. Actual: {'error': 1644, 'message': "(1644, 'BR-14 milestone sum exceeds contract')"}. Result: PASS

```sql
INSERT INTO milestones (contract_id,title,amount) VALUES (9,'race first',600);
INSERT INTO milestones (contract_id,title,amount) VALUES (9,'race second',600);
```

{'error': 1644, 'message': "(1644, 'BR-14 milestone sum exceeds contract')"}

## CC-04

Rule: concurrent gate. Expected: second waits then rejects; no invariant violation. Actual: {'error': 1062, 'message': '(1062, "Duplicate entry \'8\' for key \'proposals.uq_selected_job\'")'}. Result: PASS

```sql
UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE proposal_id=11;
UPDATE proposals SET status='CLIENT_ACCEPTED' WHERE job_id=8 AND freelancer_id=4;
```

{'error': 1062, 'message': '(1062, "Duplicate entry \'8\' for key \'proposals.uq_selected_job\'")'}

## CC-03

Rule: concurrent gate. Expected: second waits then rejects; no invariant violation. Actual: {'error': 1062, 'message': '(1062, "Duplicate entry \'9\' for key \'payments.uq_paid_milestone\'")'}. Result: PASS

```sql
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'PAYPAL','PAID');
INSERT INTO payments (milestone_id,payer_id,payee_id,amount,payment_method,payment_status) VALUES (9,3,4,500,'PAYPAL','PAID');
```

{'error': 1062, 'message': '(1062, "Duplicate entry \'9\' for key \'payments.uq_paid_milestone\'")'}

## CC-05

Rule: concurrent gate. Expected: second waits then accepts; total within limit. Actual: {'error': 0, 'message': 'accepted'}. Result: PASS

```sql
INSERT INTO milestones (contract_id,title,amount) VALUES (10,'exact first',600);
INSERT INTO milestones (contract_id,title,amount) VALUES (10,'exact second',600);
```

{'error': 0, 'message': 'accepted'}

## INV-milestone_limit

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
SELECT COUNT(*) FROM (SELECT c.contract_id FROM contracts c JOIN milestones m ON m.contract_id=c.contract_id GROUP BY c.contract_id,c.total_amount HAVING SUM(m.amount)>c.total_amount) t;
```

0

## INV-one_paid

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
SELECT COUNT(*) FROM (SELECT milestone_id FROM payments WHERE payment_status='PAID' GROUP BY milestone_id HAVING COUNT(*)>1) t;
```

0

## INV-one_selected

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
SELECT COUNT(*) FROM (SELECT job_id FROM proposals WHERE status IN ('CLIENT_ACCEPTED','CONFIRMED') GROUP BY job_id HAVING COUNT(*)>1) t;
```

0

## INV-total_subtype

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
SELECT COUNT(*) FROM users u LEFT JOIN clients c ON c.client_id=u.user_id LEFT JOIN freelancers f ON f.freelancer_id=u.user_id WHERE (c.client_id IS NOT NULL)+(f.freelancer_id IS NOT NULL)<>1;
```

0

## INV-confirmed_contract

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
SELECT COUNT(*) FROM proposals p LEFT JOIN contracts c ON c.proposal_id=p.proposal_id WHERE p.status='CONFIRMED' AND c.contract_id IS NULL;
```

0

## SEC-01

Rule: native RBAC. Expected: 1142. Actual: 1142. Result: PASS

```sql
UPDATE proposals SET status='CONFIRMED' WHERE proposal_id=11;
```

(1142, "UPDATE command denied to user 'client_1'@'localhost' for table 'proposals'")

## SEC-02

Rule: native RBAC. Expected: 1142. Actual: 1142. Result: PASS

```sql
SELECT password_hash FROM users;
```

(1142, "SELECT command denied to user 'report_reader'@'localhost' for table 'users'")

## SEC-03

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
SELECT * FROM v_contract_overview;
```

accepted

## SEC-04

Rule: native RBAC. Expected: 1142. Actual: 1142. Result: PASS

```sql
SELECT * FROM skills;
```

(1142, "SELECT command denied to user 'report_reader'@'localhost' for table 'skills'")

## SEC-05

Rule: native RBAC. Expected: 1644. Actual: 1644. Result: PASS

```sql
CALL sp_select_proposal(2,11);
```

(1644, 'Actor does not match authenticated client')

## SEC-06

Rule: native RBAC. Expected: 1644. Actual: 1644. Result: PASS

```sql
CALL sp_select_proposal(1,11);
```

(1644, 'Client does not own job')

## SEC-13

Rule: native RBAC. Expected: 1644. Actual: 1644. Result: PASS

```sql
CALL sp_select_proposal(NULL,11);
```

(1644, 'Actor does not match authenticated client')

## SEC-07

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
CALL sp_select_proposal(2,11);
```

accepted

## SEC-08

Rule: native RBAC. Expected: 1644. Actual: 1644. Result: PASS

```sql
CALL sp_confirm_proposal(4,11);
```

(1644, 'Freelancer cannot confirm this proposal')

## SEC-14

Rule: native RBAC. Expected: 1644. Actual: 1644. Result: PASS

```sql
CALL sp_advance_milestone(NULL,2,'APPROVED');
```

(1644, 'Only owning client may approve')

## SEC-15

Rule: native RBAC. Expected: 1644. Actual: 1644. Result: PASS

```sql
CALL sp_add_milestone(NULL,1,'bad',1,NULL);
```

(1644, 'Only owning client may allocate milestones')

## SEC-09

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
CALL sp_advance_milestone(1,2,'APPROVED');
```

accepted

## SEC-10

Rule: native RBAC. Expected: 1644. Actual: 1644. Result: PASS

```sql
CALL sp_advance_milestone(4,2,'APPROVED');
```

(1644, 'Only owning client may approve')

## SEC-11

Rule: native RBAC. Expected: 1370. Actual: 1370. Result: PASS

```sql
CALL sp_record_payment(1,2,'PAYPAL','PAID');
```

(1370, "execute command denied to user 'client_1'@'localhost' for routine 'mini_upwork.sp_record_payment'")

## SEC-12

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
CALL sp_record_payment(1,2,'PAYPAL','PAID');
```

accepted

## SEC-16

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
CALL sp_post_job(1,1,'RBAC demo job','Synthetic',100,500,NULL);
```

accepted

## SEC-17

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
CALL sp_submit_proposal(4,9,500,'Synthetic',30);
```

accepted

## SEC-18

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
CALL sp_select_proposal(1,12);
```

accepted

## SEC-19

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
CALL sp_confirm_proposal(4,12);
```

accepted

## SEC-20

Rule: native RBAC. Expected: 0. Actual: 0. Result: PASS

```sql
CALL sp_add_milestone(1,6,'Demo delivery',500,NULL);
```

accepted
