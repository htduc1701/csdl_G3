-- Fictional people and projects; amounts are demo USD; no real credentials.
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
USE mini_upwork;
START TRANSACTION;
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (1, 'caohonghan.1@example.test', 'Cao Hồng Hân', 'DEMO_HASH_NOT_FOR_LOGIN', 'CLIENT');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (2, 'caohuuhoa.2@example.test', 'Cao Hữu Hòa', 'DEMO_HASH_NOT_FOR_LOGIN', 'CLIENT');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (3, 'dangxuannhi.3@example.test', 'Đặng Xuân Nhi', 'DEMO_HASH_NOT_FOR_LOGIN', 'CLIENT');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (4, 'dokhanhha.4@example.test', 'Đỗ Khánh Hà', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (5, 'huynhthienhan.5@example.test', 'Huỳnh Thiên Hân', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (6, 'lebaohoa.6@example.test', 'Lê Bảo Hòa', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (7, 'dothaomai.7@example.test', 'Đỗ Thảo Mai', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
INSERT INTO users (user_id, email, full_name, password_hash, user_type) VALUES (8, 'duongtuanngan.8@example.test', 'Dương Tuấn Ngân', 'DEMO_HASH_NOT_FOR_LOGIN', 'FREELANCER');
UPDATE clients SET company_name='An Nhiên Retail', location='Hà Nội', company_description='Doanh nghiệp giả lập phục vụ đồ án, hoạt động trong lĩnh vực dịch vụ và thương mại' WHERE client_id=1;
UPDATE clients SET company_name='Mộc Trà Studio', location='Đà Nẵng', company_description='Doanh nghiệp giả lập phục vụ đồ án, hoạt động trong lĩnh vực dịch vụ và thương mại' WHERE client_id=2;
UPDATE clients SET company_name='Hải Đăng Logistics', location='TP. Hồ Chí Minh', company_description='Doanh nghiệp giả lập phục vụ đồ án, hoạt động trong lĩnh vực dịch vụ và thương mại' WHERE client_id=3;
UPDATE freelancers SET professional_title='Lập trình viên Python và cơ sở dữ liệu', bio='Chuyên phát triển và bàn giao giải pháp theo các mốc công việc rõ ràng; hồ sơ giả lập phục vụ đồ án.', hourly_rate=38 WHERE freelancer_id=4;
UPDATE freelancers SET professional_title='Nhà thiết kế UI UX', bio='Chuyên phát triển và bàn giao giải pháp theo các mốc công việc rõ ràng; hồ sơ giả lập phục vụ đồ án.', hourly_rate=29 WHERE freelancer_id=5;
UPDATE freelancers SET professional_title='Chuyên viên dữ liệu và báo cáo', bio='Chuyên phát triển và bàn giao giải pháp theo các mốc công việc rõ ràng; hồ sơ giả lập phục vụ đồ án.', hourly_rate=42 WHERE freelancer_id=6;
UPDATE freelancers SET professional_title='Lập trình viên Java backend', bio='Chuyên phát triển và bàn giao giải pháp theo các mốc công việc rõ ràng; hồ sơ giả lập phục vụ đồ án.', hourly_rate=35 WHERE freelancer_id=7;
UPDATE freelancers SET professional_title='Chuyên viên SQL', bio='Chuyên phát triển và bàn giao giải pháp theo các mốc công việc rõ ràng; hồ sơ giả lập phục vụ đồ án.', hourly_rate=27 WHERE freelancer_id=8;
INSERT INTO skills (skill_name) VALUES ('SQL'), ('Python'), ('Design'), ('Java'), ('Testing'), ('Analytics');
INSERT INTO job_categories (category_name) VALUES ('Software'), ('Design'), ('Data');
INSERT INTO freelancer_skills VALUES (4,1,'EXPERT'),(4,2,'ADVANCED'),(4,5,'ADVANCED'),(5,3,'EXPERT'),(5,5,'INTERMEDIATE'),(6,1,'ADVANCED'),(6,2,'ADVANCED'),(6,6,'EXPERT'),(7,4,'ADVANCED'),(8,1,'INTERMEDIATE');
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (1,1,1,'Xây dựng cổng đặt hàng cho An Nhiên Retail','Phân tích yêu cầu, triển khai giải pháp theo phạm vi thống nhất và bàn giao hướng dẫn sử dụng. Nghiệm thu dựa trên bộ kiểm tra chức năng và dữ liệu đối soát.',500,1000,DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY),DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY));
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (2,1,2,'Thiết kế bộ giao diện đặt trà cho Mộc Trà Studio','Phân tích yêu cầu, triển khai giải pháp theo phạm vi thống nhất và bàn giao hướng dẫn sử dụng. Nghiệm thu dựa trên bộ kiểm tra chức năng và dữ liệu đối soát.',400,800,DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY),DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY));
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (3,2,3,'Dashboard theo dõi giao hàng của Mộc Trà Studio','Phân tích yêu cầu, triển khai giải pháp theo phạm vi thống nhất và bàn giao hướng dẫn sử dụng. Nghiệm thu dựa trên bộ kiểm tra chức năng và dữ liệu đối soát.',750,1500,DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY),DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY));
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (4,2,1,'API quản lý yêu cầu cho Mộc Trà Studio','Phân tích yêu cầu, triển khai giải pháp theo phạm vi thống nhất và bàn giao hướng dẫn sử dụng. Nghiệm thu dựa trên bộ kiểm tra chức năng và dữ liệu đối soát.',300,600,DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY),DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY));
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (5,3,1,'Pipeline đối soát đơn vận chuyển của Hải Đăng Logistics','Phân tích yêu cầu, triển khai giải pháp theo phạm vi thống nhất và bàn giao hướng dẫn sử dụng. Nghiệm thu dựa trên bộ kiểm tra chức năng và dữ liệu đối soát.',1000,2000,DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY),DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY));
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (6,3,3,'Báo cáo chi phí tuyến giao hàng Hải Đăng Logistics','Phân tích yêu cầu, triển khai giải pháp theo phạm vi thống nhất và bàn giao hướng dẫn sử dụng. Nghiệm thu dựa trên bộ kiểm tra chức năng và dữ liệu đối soát.',450,900,DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY),DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY));
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (7,1,2,'Thiết kế trang giới thiệu bộ sưu tập An Nhiên Retail','Phân tích yêu cầu, triển khai giải pháp theo phạm vi thống nhất và bàn giao hướng dẫn sử dụng. Nghiệm thu dựa trên bộ kiểm tra chức năng và dữ liệu đối soát.',250,500,DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY),DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY));
INSERT INTO jobs (job_id, client_id, category_id, title, description, budget_min, budget_max, created_at, deadline) VALUES (8,2,3,'Tối ưu truy vấn báo cáo tồn kho Mộc Trà Studio','Phân tích yêu cầu, triển khai giải pháp theo phạm vi thống nhất và bàn giao hướng dẫn sử dụng. Nghiệm thu dựa trên bộ kiểm tra chức năng và dữ liệu đối soát.',600,1200,DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY),DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (1,1,4,1000,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (2,1,6,950,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (3,2,5,800,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (4,2,4,750,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (5,3,6,1500,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (6,3,8,1400,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (7,4,7,600,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (8,5,4,2000,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (9,5,7,1900,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (10,6,6,900,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
INSERT INTO proposals (proposal_id,job_id,freelancer_id,proposed_amount,cover_letter,estimated_days,submitted_at) VALUES (11,8,8,1200,'Tôi đề xuất triển khai theo ba bước: làm rõ yêu cầu, phát triển giải pháp và kiểm thử bàn giao; trao đổi tiến độ định kỳ với khách hàng.',60,DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY));
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
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (1,1,'Thiết kế và triển khai — Xây dựng cổng đặt hàng cho An Nhiên Retail',400,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (2,1,'Kiểm thử và bàn giao — Xây dựng cổng đặt hàng cho An Nhiên Retail',600,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (3,2,'Thiết kế và triển khai — Thiết kế bộ giao diện đặt trà cho Mộc Trà Studio',300,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (4,2,'Kiểm thử và bàn giao — Thiết kế bộ giao diện đặt trà cho Mộc Trà Studio',500,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (5,3,'Thiết kế và triển khai — Dashboard theo dõi giao hàng của Mộc Trà Studio',500,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (6,3,'Kiểm thử và bàn giao — Dashboard theo dõi giao hàng của Mộc Trà Studio',1000,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (7,4,'Thiết kế và triển khai — API quản lý yêu cầu cho Mộc Trà Studio',200,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (8,4,'Kiểm thử và bàn giao — API quản lý yêu cầu cho Mộc Trà Studio',400,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (9,5,'Thiết kế và triển khai — Pipeline đối soát đơn vận chuyển của Hải Đăng Logistics',500,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
INSERT INTO milestones (milestone_id,contract_id,title,amount,due_date) VALUES (10,5,'Kiểm thử và bàn giao — Pipeline đối soát đơn vận chuyển của Hải Đăng Logistics',1500,DATE_ADD(CURRENT_DATE, INTERVAL 20 DAY));
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
INSERT INTO payments (
    payment_id,
    milestone_id,
    payment_method,
    payment_status
) VALUES
    (1,1,'BANK_TRANSFER','FAILED'),
    (2,1,'BANK_TRANSFER','PAID'),
    (3,3,'BANK_TRANSFER','PAID'),
    (4,5,'BANK_TRANSFER','PENDING'),
    (5,7,'BANK_TRANSFER','PAID'),
    (6,9,'BANK_TRANSFER','FAILED');
COMMIT;
