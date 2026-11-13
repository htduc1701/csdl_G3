-- Run as a MySQL administrator after INSTALL_DATABASE.sql.
-- These credentials are for the local classroom demo in app/db.py.
USE mini_upwork;

ALTER USER 'client_1'@'localhost'
    IDENTIFIED BY 'Client1@123' ACCOUNT UNLOCK;
ALTER USER 'freelancer_4'@'localhost'
    IDENTIFIED BY 'Freelancer4@123' ACCOUNT UNLOCK;
ALTER USER 'payment_service'@'localhost'
    IDENTIFIED BY 'Payment@123' ACCOUNT UNLOCK;
