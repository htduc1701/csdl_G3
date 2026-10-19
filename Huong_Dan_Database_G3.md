# Hướng dẫn database G3 — bản dữ liệu gần thực tế

Áp dụng cho gói G3_Database_Project.zip mới: MySQL 8.0.42, schema mini_upwork, 11 bảng, 7.223 bản ghi; riêng jobs có 1.008 công việc. Tên người/công ty đều giả lập, email example.test, tiền mẫu tính bằng USD.

## 1. Cần dùng những file nào trước?

Để chạy và trình bày bài, trước tiên chỉ cần ba file:

| File | Việc cần làm |
|---|---|
| INSTALL_DATABASE.sql | Cài mới toàn bộ cấu trúc, trigger, view, procedure, dữ liệu và phân quyền mẫu |
| sql/09_verify_counts.sql | Kiểm tra số bản ghi sau khi cài |
| sql/06_queries.sql | Chạy 12 truy vấn thống kê và nghiệp vụ |

REALISTIC_SAMPLE_DATA.sql là file **chỉ chứa phần nạp dữ liệu** cùng các thao tác chuyển trạng thái cần thiết. Nó không thay thế file cài đầy đủ. INSTALL_DATABASE.sql đã chứa dữ liệu này; không chạy cả hai trên cùng database đã nạp.

Database thực sự được lưu trong MySQL Server sau khi chạy SQL. File .sql là lệnh tạo/nạp/truy vấn, không phải một ứng dụng hay file database mở bằng nhấp đúp.

## 2. Vai trò từng file trong gói ZIP

### 2.1. Các file ở thư mục gốc

| File | Vai trò | Có cần chạy không? |
|---|---|---|
| README.md | Hướng dẫn tổng quan, điều kiện cài và giới hạn bằng chứng kiểm thử | Đọc trước |
| INSTALL_DATABASE.sql | Ghép 01 → 05 → 08 → 07 → 09, tạo hệ thống và nạp đầy đủ 7.223 bản ghi | Chạy một lần khi cài mới |
| REALISTIC_SAMPLE_DATA.sql | Ghép dữ liệu 05 và 08, liệt kê bản ghi bằng INSERT ... VALUES; có UPDATE để mô phỏng quy trình | Chỉ chạy nếu đã cài 01–04 và các bảng nghiệp vụ còn trống |
| compose.yaml | Cấu hình Docker chạy MySQL 8.0.42, cổng máy host 3307 và volume lưu dữ liệu | Tùy chọn, khi dùng Docker |
| requirements.txt | Thư viện PyMySQL để chạy các chương trình kiểm thử Python | Cài nếu chạy kiểm thử Python |
| requirements-docs.txt | Thư viện python-docx và matplotlib hỗ trợ xử lý tài liệu/biểu đồ | Không cần để chạy database |

### 2.2. Thư mục sql — mã SQL

| File | Vai trò cụ thể |
|---|---|
| 01_schema.sql | Tạo schema mini_upwork và 11 bảng; khai báo PK, FK, UNIQUE, CHECK, NOT NULL, DEFAULT và kiểu dữ liệu |
| 02_triggers.sql | Trigger bảo vệ subtype, thứ tự đồng thuận, tự tạo contract, giới hạn milestone và tính hợp lệ của payment |
| 03_views_indexes.sql | Tạo 3 view: v_job_proposals, v_contract_overview, v_client_spend; tạo index phục vụ lọc ngân sách và milestone |
| 04_procedures.sql | 7 procedure cho đăng job, nộp/chọn/xác nhận proposal, thêm/chuyển trạng thái milestone và ghi nhận payment |
| 05_seed.sql | Bộ seed nền nhỏ 75 bản ghi, đã đổi sang tên và nội dung giả lập gần thực tế |
| 06_queries.sql | 12 truy vấn nâng cao về proposal, hợp đồng, thanh toán, kỹ năng và tiến độ |
| 07_security.sql | Tạo 4 role, tài khoản MySQL mẫu và GRANT/REVOKE; các tài khoản mẫu được khóa mặc định |
| 08_seed_1000_jobs.sql | Bổ sung 1.000 job cùng người dùng, proposal, contract, milestone và payment liên quan; kết hợp 05 thành 7.223 bản ghi |
| 09_verify_counts.sql | Đếm chính xác từng bảng bằng COUNT(*) và tính tổng bằng window function |

01–05, 08, 07, 09 đã có trong INSTALL_DATABASE.sql. Không chạy lại từng file này sau khi cài tổng hợp thành công.

### 2.3. Thư mục tests — chương trình kiểm thử

| File | Vai trò | Cách sử dụng |
|---|---|---|
| verify_large_dataset.py | Kiểm tra số bản ghi, 9 nhóm bất biến dữ liệu, 5 kiểm tra nội dung giả lập và thực thi 12 query; chỉ đọc database, ghi file kết quả | Dùng cho bộ dữ liệu mới |
| run_tests.py | Kiểm thử positive/negative, concurrency, kết quả query của seed nhỏ; tùy chọn kiểm thử quyền | Chỉ dùng trên MySQL riêng cho kiểm thử; có sửa dữ liệu và --install xóa/tạo lại mini_upwork |
| run_performance.py | Tạo mini_upwork_perf riêng với 5.000 job/10.000 proposal, so sánh truy vấn dùng/bỏ index rồi xóa database benchmark | Tùy chọn cho phần hiệu năng; không dùng thay dữ liệu demo |

Không chạy run_tests.py trên database demo lớn: các kỳ vọng của nó dành cho seed nhỏ, và --install có lệnh DROP DATABASE. Ngay cả khi không dùng --install, đây vẫn là chương trình có thay đổi dữ liệu.

### 2.4. Thư mục docs — tài liệu giải thích

| File | Vai trò |
|---|---|
| audit_report.md | Danh sách vấn đề audit, mức độ, Business Rule, phương án và trạng thái xử lý |
| business_rules.json | Nội dung Business Rules ở dạng dữ liệu có cấu trúc |
| business_rule_matrix.md | Ánh xạ Business Rule sang cơ chế bảo vệ và kiểm thử |
| schema_metadata.json | Metadata/data dictionary của các bảng và cột |
| physical_schema.mmd | Mã Mermaid mô tả sơ đồ vật lý; xem bằng công cụ hỗ trợ Mermaid |
| mapping_appendix.md | Giải thích ánh xạ thực thể/EER sang bảng vật lý và quan hệ |
| normalization.md | Phân tích FD, khóa và chuẩn hóa; ghi rõ ngoại lệ PAYMENT, không tuyên bố toàn bộ đạt BCNF |
| trigger_catalog.md | Danh mục trigger, mục đích và cách kiểm chứng |
| query_catalog.json | SQL, câu hỏi nghiệp vụ, expected result và giải thích 12 truy vấn; expected của seed nhỏ |
| query_report.md | Báo cáo query và hiệu năng từ lần chạy seed nhỏ trước đây |
| test_report.md | Báo cáo kiểm thử ràng buộc/concurrency của seed nhỏ trước đây |
| security.md | Giải thích tài khoản, role, quyền và cách dùng procedure |
| large_dataset_report.md | Báo cáo số đếm, kiểm tra và kết quả query đã chạy trên bộ mới 7.223 bản ghi; mỗi query hiển thị tối đa 10 dòng đầu |
| realistic_preview.json | Một số tên người, công ty và job tiêu biểu để xem nhanh; không phải toàn bộ dữ liệu |

### 2.5. Thư mục evidence — bằng chứng chạy thực tế

| File | Vai trò |
|---|---|
| large_dataset_results.json | Kết quả mới của bộ 7.223 bản ghi: môi trường, số đếm, bất biến, nội dung và query |
| environment.json | Phiên bản/cấu hình MySQL và thông tin index từ lần kiểm thử seed nhỏ |
| query_results.json | Kết quả, thời gian và EXPLAIN của các query trên seed nhỏ |
| test_results.json | Kết quả kiểm thử ràng buộc và concurrency trên seed nhỏ |
| security_results.json | Kết quả kiểm thử tài khoản và quyền trên môi trường kiểm thử trước đây |
| performance_results.json | Kết quả benchmark riêng 5.000 job/10.000 proposal, không phải số bản ghi demo |
| verification_summary.json | Tổng hợp lần kiểm thử seed nhỏ trước đây |

Kết quả cũ không có nghĩa là đã chạy lại toàn bộ bộ test đó trên dữ liệu mới. Khi trình bày dữ liệu mới, dùng large_dataset_report.md và large_dataset_results.json.

## 3. Cài và chạy thử bằng MySQL Workbench trên Windows

### Bước 1 — Chuẩn bị

Cần MySQL Server 8.0 và MySQL Workbench. Workbench là giao diện kết nối; phải có MySQL Server đang chạy. Gói được kiểm chứng bằng MySQL 8.0.42. Không chạy bằng SQL Server hay PostgreSQL.

Giải nén ZIP vào một thư mục, ví dụ C:\G3_Database_Project. Giữ nguyên cấu trúc sql, docs, tests, evidence.

### Bước 2 — Kết nối MySQL

Mở Workbench → MySQL Connections → chọn kết nối đang có hoặc dấu +:

- Hostname: 127.0.0.1.
- Port: cổng MySQL thực tế, thường là 3306; nếu dùng compose.yaml của gói thì 3307.
- Username: tài khoản quản trị của bạn, ví dụ root.
- Password: mật khẩu MySQL do bạn đặt.

Chọn Test Connection rồi mở kết nối. Tài khoản cài phải có quyền tạo database, table, trigger, view, procedure, role và user. Tài khoản demo trong 07_security.sql chưa dùng đăng nhập ngay vì đang bị khóa.

### Bước 3 — Cài mới

Nếu mini_upwork đã chứa bộ cũ hoặc dữ liệu cần giữ, hãy sao lưu và dùng MySQL instance riêng cho bộ mới; không chạy chồng bộ cài. Không cần xóa database cũ để xem hướng dẫn này.

Trong Workbench:

1. File → Open SQL Script → chọn INSTALL_DATABASE.sql.
2. Bỏ vùng chọn văn bản nếu có, chạy toàn bộ script bằng nút tia sét Execute All/Selection hoặc Ctrl+Shift+Enter.
3. Theo dõi Action Output phía dưới; dừng khi có lỗi đỏ và xem lỗi đầu tiên.
4. Khi thành công, refresh mục SCHEMAS bên trái. Mở mini_upwork → Tables sẽ có 11 bảng; Views có 3 view.

Nếu báo Table already exists, database không còn là database trống. Không chạy tiếp hoặc bỏ qua lỗi để cố nạp.

### Bước 4 — Kiểm tra dữ liệu đã nạp

Mở sql/09_verify_counts.sql và chạy toàn bộ. Kết quả đúng của bộ mới:

| Bảng | Bản ghi |
|---|---:|
| users | 248 |
| clients | 43 |
| freelancers | 205 |
| skills | 26 |
| freelancer_skills | 610 |
| job_categories | 11 |
| jobs | 1.008 |
| proposals | 1.811 |
| contracts | 605 |
| milestones | 1.810 |
| payments | 846 |
| **Tổng** | **7.223** |

Cột total_rows trả về 7223 trên từng hàng của truy vấn đếm; đó là tổng chung, không phải mỗi bảng có 7223 dòng.

### Bước 5 — Chạy truy vấn mẫu

Mở sql/06_queries.sql. Chạy USE mini_upwork trước. Bôi đen từng câu SELECT/CTE hoàn chỉnh để chạy riêng; hoặc chạy toàn bộ để nhận nhiều result tab. Có 12 câu Q-01 đến Q-12.

Để xem kế hoạch thực thi một truy vấn, chạy:

```sql
USE mini_upwork;
EXPLAIN ANALYZE
SELECT job_id, title, budget_max
FROM jobs
WHERE status = 'OPEN' AND budget_max >= 2000
ORDER BY budget_max DESC
LIMIT 20;
```

Thời gian đo trên máy của bạn có thể khác bằng chứng đã lưu.

## 4. Xem dữ liệu trong database

### Cách 1 — Không cần viết SQL

Trong SCHEMAS → mini_upwork → Tables, nhấp phải users hoặc jobs → Select Rows - Limit 1000. Workbench sẽ mở Result Grid có dữ liệu.

Bảng jobs có 1008 dòng nên Limit 1000 chỉ hiện tối đa 1000 dòng. Muốn xem đủ, chọn giới hạn lớn hơn ở thanh công cụ hoặc chạy SELECT bên dưới và điều chỉnh tùy chọn Limit Rows nếu Workbench đang áp giới hạn.

### Cách 2 — Viết câu SELECT

Mở một SQL tab mới rồi chạy từng câu:

```sql
USE mini_upwork;

-- Người dùng: không cần hiển thị password_hash
SELECT user_id, full_name, email, user_type
FROM users ORDER BY user_id;

-- Toàn bộ công việc: 1008 dòng
SELECT job_id, title, budget_min, budget_max, status, deadline
FROM jobs ORDER BY job_id;

-- Tìm tên dự án/công việc
SELECT job_id, title, description, budget_max
FROM jobs
WHERE title LIKE '%dashboard%';

-- Client và tên công ty
SELECT c.client_id, u.full_name, c.company_name, c.location
FROM clients c JOIN users u ON u.user_id = c.client_id
ORDER BY c.client_id;

-- Freelancer và nghề nghiệp
SELECT f.freelancer_id, u.full_name,
       f.professional_title, f.hourly_rate, f.experience_level
FROM freelancers f JOIN users u ON u.user_id = f.freelancer_id
ORDER BY f.freelancer_id;

-- Job, người đăng, công ty và số proposal
SELECT j.job_id, j.title, u.full_name AS client_name,
       c.company_name, COUNT(p.proposal_id) AS proposal_count
FROM jobs j
JOIN clients c ON c.client_id = j.client_id
JOIN users u ON u.user_id = c.client_id
LEFT JOIN proposals p ON p.job_id = j.job_id
GROUP BY j.job_id, j.title, u.full_name, c.company_name
ORDER BY j.job_id;

-- Chi tiết các giai đoạn và thanh toán của hợp đồng 1
-- Một milestone có thể có nhiều payment attempt FAILED/PENDING/PAID
SELECT m.milestone_id, m.title, m.amount, m.status,
       p.payment_id, p.payment_status, p.payment_method
FROM milestones m
LEFT JOIN payments p ON p.milestone_id = m.milestone_id
WHERE m.contract_id = 1
ORDER BY m.milestone_id, p.payment_id;

-- Chỉ tính tiền thanh toán thành công
SELECT COALESCE(SUM(amount), 0) AS total_paid_usd
FROM payments WHERE payment_status = 'PAID';

-- Ba báo cáo tổng hợp có sẵn
SELECT * FROM v_job_proposals ORDER BY job_id;
SELECT * FROM v_contract_overview ORDER BY contract_id;
SELECT * FROM v_client_spend ORDER BY client_id;
```

Muốn lưu kết quả ra CSV, dùng nút Export trong Result Grid. Không cần cài Python để xem dữ liệu theo hai cách trên.

## 5. Kiểm chứng tự động bộ dữ liệu mới — tùy chọn

Mở PowerShell tại thư mục đã giải nén, nơi có requirements.txt. Cần cài Python trước. Ví dụ cho MySQL cài trực tiếp trên Windows:

```powershell
py -m pip install -r requirements.txt
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$env:DB_PASSWORD = Read-Host 'Nhập mật khẩu MySQL' -MaskInput
py tests/verify_large_dataset.py
Remove-Item Env:DB_PASSWORD
```

-MaskInput cần PowerShell 7. Nếu đang dùng Windows PowerShell 5.1, thay dòng nhập mật khẩu bằng:

```powershell
$g3Secret = Read-Host 'Nhập mật khẩu MySQL' -AsSecureString
$env:DB_PASSWORD = [System.Net.NetworkCredential]::new('', $g3Secret).Password
```

Nếu dùng Docker của gói thì đổi DB_PORT thành 3307. Chương trình kiểm tra database và ghi evidence/large_dataset_results.json. Khi thành công có passed: true. Nếu bạn thêm/sửa dữ liệu, các kiểm tra số đếm chính xác có thể không còn đạt.

## 6. Chạy MySQL bằng Docker — chỉ khi muốn dùng môi trường riêng

Không bắt buộc dùng Docker nếu đã có MySQL. Nếu có Docker Desktop đang chạy, mở PowerShell tại thư mục gói:

```powershell
$g3Secret = Read-Host 'Đặt mật khẩu root cho MySQL demo mới' -AsSecureString
$env:MYSQL_ROOT_PASSWORD = [System.Net.NetworkCredential]::new('', $g3Secret).Password
docker compose up -d
```

Đợi MySQL khởi động rồi dùng Workbench kết nối 127.0.0.1:3307, user root và mật khẩu vừa đặt. Sau đó cài INSTALL_DATABASE.sql theo mục 3. Compose chỉ khởi động server, không tự import SQL.

Để dừng server: docker compose stop. Volume mysql_data giữ dữ liệu; không dùng docker compose down -v nếu cần giữ database. Mật khẩu môi trường chỉ khởi tạo root lần đầu khi volume còn trống; đổi biến này không tự đổi mật khẩu của volume cũ.

## 7. Trình tự trình bày bài demo

1. Mở mini_upwork → Tables, chỉ ra 11 bảng.
2. Chạy sql/09_verify_counts.sql, chỉ ra 1008 job và tổng 7223 bản ghi.
3. Xem users, clients, jobs để minh họa tên và mô tả gần thực tế.
4. Xem proposals → contracts → milestones → payments để giải thích quy trình.
5. Chạy một số truy vấn trong sql/06_queries.sql và các view.
6. Mở docs/large_dataset_report.md để trình bày bằng chứng mới; giải thích tài liệu test seed nhỏ là kết quả của bộ kiểm thử riêng.

Bộ này triển khai database và dữ liệu, không có giao diện website. Ngày mẫu được sinh tương đối theo ngày import ở nhiều vị trí nên kết quả liên quan ngày hiện tại có thể thay đổi.
