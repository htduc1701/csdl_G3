USE mini_upwork;

-- CLIENT: 1, 2, 3
ALTER USER 'client_1'@'localhost'
    IDENTIFIED BY 'Client1@123' ACCOUNT UNLOCK;

ALTER USER 'client_2'@'localhost'
    IDENTIFIED BY 'Client1@123' ACCOUNT UNLOCK;

ALTER USER 'client_3'@'localhost'
    IDENTIFIED BY 'Client1@123' ACCOUNT UNLOCK;

-- FREELANCER: 4, 5, 6, 7
ALTER USER 'freelancer_4'@'localhost'
    IDENTIFIED BY 'Freelancer4@123' ACCOUNT UNLOCK;

ALTER USER 'freelancer_5'@'localhost'
    IDENTIFIED BY 'Freelancer4@123' ACCOUNT UNLOCK;

ALTER USER 'freelancer_6'@'localhost'
    IDENTIFIED BY 'Freelancer4@123' ACCOUNT UNLOCK;

ALTER USER 'freelancer_7'@'localhost'
    IDENTIFIED BY 'Freelancer4@123' ACCOUNT UNLOCK;

-- TÀI KHOẢN THANH TOÁN
ALTER USER 'payment_service'@'localhost'
    IDENTIFIED BY 'Payment@123' ACCOUNT UNLOCK;

-- KÍCH HOẠT ROLE MẶC ĐỊNH
SET DEFAULT ROLE 'market_client' TO
    'client_1'@'localhost',
    'client_2'@'localhost',
    'client_3'@'localhost';

SET DEFAULT ROLE 'market_freelancer' TO
    'freelancer_4'@'localhost',
    'freelancer_5'@'localhost',
    'freelancer_6'@'localhost',
    'freelancer_7'@'localhost';

SET DEFAULT ROLE 'market_payment' TO
    'payment_service'@'localhost';

-- KIỂM TRA: account_locked = N LÀ ĐÃ MỞ KHÓA
SELECT User, Host, account_locked
FROM mysql.user
WHERE Host = 'localhost'
  AND User IN (
      'client_1', 'client_2', 'client_3',
      'freelancer_4', 'freelancer_5',
      'freelancer_6', 'freelancer_7',
      'payment_service'
  )
ORDER BY User;