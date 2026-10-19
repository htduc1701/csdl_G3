# Hướng dẫn sử dụng database Mini Upwork G3

**Môn học:** INT1313 – Databases, PTIT  
**Dự án:** Freelance Marketplace Ecosystem  
**Database:** `mini_upwork`  
**Phiên bản đã kiểm thử:** MySQL 8.0.42, InnoDB, READ COMMITTED  
**Dữ liệu:** 7.223 dòng trong 11 bảng, gồm 1.008 jobs

Tài liệu giải thích vai trò từng file trong gói `G3_Database_Project.zip`, cách cài đặt, chạy thử và xem dữ liệu. Bộ SQL đã được chạy trong môi trường kiểm thử; bạn cần import vào MySQL Server trên máy để sử dụng và demo.

## 1. Ba file cần quan tâm trước tiên

| File | Khi nào dùng |
|---|---|
| `INSTALL_DATABASE.sql` | Cài mới database và nạp dữ liệu. |
| `sql/09_verify_counts.sql` | Kiểm tra số dòng từng bảng và toàn database. |
| `sql/06_queries.sql` | Chạy thử 12 truy vấn báo cáo nâng cao. |

Nếu đã chạy `INSTALL_DATABASE.sql` thành công, không chạy lại các file tạo bảng hoặc nạp dữ liệu. File tổng hợp đã chứa các phần đó; `06_queries.sql` là file chạy báo cáo riêng sau khi cài.

## 2. Vai trò từng file

### 2.1 Các file ngoài cùng

| File | Vai trò |
|---|---|
| `INSTALL_DATABASE.sql` | Tạo database, bảng, ràng buộc, triggers, views, procedures, seed nhỏ, seed mở rộng, phân quyền và truy vấn đếm dòng. |
| `README.md` | Hướng dẫn cài, chạy và các lưu ý. Mở bằng VS Code hoặc Notepad. |
| `requirements.txt` | Thư viện Python phục vụ kết nối và kiểm thử MySQL. |
| `requirements-docs.txt` | Thư viện hỗ trợ xử lý tài liệu; không cần để chạy database. |
| `compose.yaml` | Cấu hình chạy MySQL bằng Docker; không cần dùng nếu đã cài MySQL Server trực tiếp. |

### 2.2 Thư mục sql

| File | Vai trò |
|---|---|
| `01_schema.sql` | Tạo 11 bảng; định nghĩa kiểu dữ liệu, PK, FK, UNIQUE, CHECK, NOT NULL và DEFAULT. |
| `02_triggers.sql` | Tạo 21 triggers bảo vệ subtype, trạng thái proposal, contract, milestone và payment. |
| `03_views_indexes.sql` | Tạo 3 views báo cáo và indexes hỗ trợ truy vấn. |
| `04_procedures.sql` | Tạo 7 procedures cho đăng job, nộp/chọn/xác nhận proposal, cập nhật milestone và ghi nhận payment. |
| `05_seed.sql` | Nạp bộ dữ liệu nhỏ ban đầu: 75 dòng tổng cộng. |
| `06_queries.sql` | Chứa 12 truy vấn nâng cao để thống kê và demo. |
| `07_security.sql` | Tạo roles, tài khoản MySQL mẫu, cấp và thu hồi quyền. |
| `08_seed_1000_jobs.sql` | Bổ sung 1.000 jobs và dữ liệu liên quan, đưa tổng lên 7.223 dòng khi bắt đầu từ seed nhỏ. |
| `09_verify_counts.sql` | Đếm chính xác số dòng từng bảng và tổng toàn database bằng COUNT(*). |

Nếu cài thủ công từng phần thay cho file tổng hợp, thứ tự là **01 → 02 → 03 → 04 → 05 → 08 → 07 → 09**. Sau đó chạy **06** để xem báo cáo. Chỉ chọn một cách cài, không chạy cả hai lên cùng bộ bảng đã có.

### 2.3 Thư mục tests

| File | Vai trò |
|---|---|
| `verify_large_dataset.py` | Kiểm tra bộ 7.223 dòng, chín invariant và chạy 12 truy vấn. Chỉ đọc database; ghi kết quả JSON vào thư mục evidence tại máy chạy. |
| `run_tests.py` | Bộ kiểm thử chi tiết trên fixture nhỏ. Chế độ `--install` có bước DROP và dựng lại `mini_upwork` trong quy trình. |
| `run_performance.py` | Tạo database thử nghiệm riêng `mini_upwork_perf` để benchmark index, rồi xóa fixture đó. |

**Không chạy `run_tests.py --install` trên database demo lớn hoặc dữ liệu cần giữ.** Kiểm thử nhỏ phải thực hiện trên MySQL instance dùng riêng. Để kiểm tra bộ lớn hiện tại, dùng `verify_large_dataset.py`.

### 2.4 Thư mục docs

| File | Nội dung |
|---|---|
| `audit_report.md` | Vấn đề phát hiện khi audit và phương án xử lý. |
| `business_rules.json` | Danh sách 16 Business Rules. |
| `business_rule_matrix.md` | Đối chiếu Business Rules với cơ chế bảo vệ dữ liệu. |
| `mapping_appendix.md` | Giải thích chuyển thực thể và quan hệ thành bảng. |
| `physical_schema.mmd` | Mã Mermaid mô tả các quan hệ trong schema. |
| `schema_metadata.json` | Metadata của các thuộc tính trong schema. |
| `normalization.md` | Functional dependencies, candidate keys và chuẩn hóa; có giải thích ngoại lệ 3NF của PAYMENT. |
| `trigger_catalog.md` | SQL, mục đích và tham chiếu kiểm thử của từng trigger. |
| `security.md` | Phân quyền, tài khoản và giới hạn bảo mật. |
| `query_catalog.json` | Danh mục truy vấn và câu hỏi nghiệp vụ. |
| `query_report.md` | Kết quả truy vấn trên bộ seed nhỏ. |
| `test_report.md` | Chi tiết các kiểm thử của bộ seed nhỏ. |
| `large_dataset_report.md` | Số dòng, phân bố trạng thái và kết quả truy vấn trên bộ 7.223 dòng mới. |

### 2.5 Thư mục evidence

| File | Nội dung |
|---|---|
| `large_dataset_results.json` | Bằng chứng thực thi mới trên bộ 7.223 dòng. |
| `environment.json` | Phiên bản và cấu hình MySQL của lần kiểm thử seed nhỏ. |
| `test_results.json` | Kết quả kiểm thử nghiệp vụ và đồng thời trên fixture nhỏ. |
| `security_results.json` | Kết quả kiểm thử phân quyền trên seed nhỏ. |
| `query_results.json` | Kết quả và execution plans của 12 truy vấn trên seed nhỏ. |
| `performance_results.json` | Kết quả benchmark hiệu năng. |
| `verification_summary.json` | Tổng hợp 104 kiểm tra của lần chạy seed nhỏ. |

Các file Markdown, JSON và Mermaid là tài liệu/bằng chứng; không cần chạy chúng để tạo database. Kết quả 104 kiểm tra là của bộ nhỏ trước đây, không phải tuyên bố chạy lại 104 kiểm tra trên bộ lớn.

## 3. Cài mới bằng MySQL Workbench

### 3.1 Chuẩn bị

- Có **MySQL Server** đang chạy và **MySQL Workbench**.
- Server lưu và xử lý database; Workbench là giao diện kết nối và thao tác.
- Có tài khoản cài đặt đủ quyền tạo database, bảng, trigger, view, procedure, role và user.
- Giải nén `G3_Database_Project.zip` bằng **Extract All**.

Nếu dùng MySQL cài trực tiếp, kết nối thường là `127.0.0.1:3306`, nhưng hãy dùng đúng cổng đã thiết lập trên máy. Nếu dùng `compose.yaml` đi kèm, cổng từ máy host là `127.0.0.1:3307`. File Docker không tự import SQL.

### 3.2 Chạy file tổng hợp

1. Mở Workbench, kết nối MySQL bằng tài khoản quản trị.
2. Chọn **File → Open SQL Script**, mở `INSTALL_DATABASE.sql` trong thư mục đã giải nén.
3. Không bôi chọn riêng một đoạn nếu muốn chạy toàn bộ file.
4. Chọn **Query → Execute (All or Selection)**.
5. Bật **Stop Script Execution On Errors**. Nếu gặp lỗi đỏ, dừng và xem thông báo, không bỏ qua để import tiếp.
6. Ở khung **Schemas** bên trái, nhấn Refresh.
7. Mở **mini_upwork → Tables** để thấy 11 bảng.

**Chỉ dùng file tổng hợp cho database mới.** Nếu báo bảng đã tồn tại, không chạy lại toàn bộ và không tự xóa database đang có. Các tài khoản MySQL mẫu bị khóa; DBA cần thiết lập bí mật riêng trước khi dùng. Tài khoản quản trị phục vụ cài đặt, không nên dùng làm tài khoản ứng dụng.

### 3.3 Nếu đã có bộ seed nhỏ

Nếu bạn đã cài 01 đến 05 trước đây:

1. Mở và chạy riêng `sql/08_seed_1000_jobs.sql` một lần trong phiên độc lập.
2. Chạy `sql/09_verify_counts.sql` để đếm lại.

Không chạy lại `INSTALL_DATABASE.sql` hoặc `05_seed.sql`. Extension giữ seed cũ, kiểm tra vùng ID trước khi thêm và rollback dữ liệu thêm nếu lỗi. Nếu có dữ liệu riêng ngoài seed nhỏ, số tổng thực tế có thể khác 7.223.

## 4. Xem dữ liệu

### 4.1 Xem trực tiếp bằng giao diện

Trong **Schemas → mini_upwork → Tables**, nhấn chuột phải vào bảng cần xem và chọn **Select Rows – Limit 1000**. Kết quả hiện trong bảng dữ liệu phía dưới vùng nhập SQL.

Workbench mặc định có giới hạn 1.000 dòng trả về. Muốn xem nhiều hơn, đổi lựa chọn **Limit Rows** trên thanh công cụ, hoặc dùng truy vấn có phân trang. Dùng COUNT(*) để biết số lượng thật, không suy ra từ số dòng đang hiển thị.

### 4.2 Xem bằng SQL

Mở một SQL tab mới. Bôi chọn đoạn cần chạy rồi chọn Execute (All or Selection), hoặc đặt con trỏ trong câu lệnh và dùng Execute Current Statement.

```sql
USE mini_upwork;

-- Xem 20 tài khoản
SELECT *
FROM users
ORDER BY user_id
LIMIT 20;

-- Xem 20 công việc
SELECT *
FROM jobs
ORDER BY job_id
LIMIT 20;

-- Xem 20 lần thanh toán
SELECT *
FROM payments
ORDER BY payment_id
LIMIT 20;
```

Xem danh sách bảng và cấu trúc một bảng:

```sql
USE mini_upwork;
SHOW TABLES;
DESCRIBE jobs;
SHOW CREATE TABLE jobs;
```

### 4.3 Kiểm tra số dòng

```sql
USE mini_upwork;
SELECT COUNT(*) AS total_jobs
FROM jobs;
```

Kết quả với bộ cài mới là **1008**. Chạy `sql/09_verify_counts.sql` để có đủ 11 bảng và cột `total_rows = 7223`.

| Bảng | Số dòng |
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

Đây là hơn 1.000 dòng tổng cộng, không phải mỗi bảng có ít nhất 1.000 dòng. Riêng bảng jobs cũng vượt 1.000 dòng.

## 5. Chạy thử truy vấn báo cáo

### 5.1 Xem các views

```sql
USE mini_upwork;

-- Job và số proposal
SELECT *
FROM v_job_proposals
ORDER BY job_id
LIMIT 20;

-- Tổng quan hợp đồng, milestone và thanh toán
SELECT *
FROM v_contract_overview
ORDER BY contract_id
LIMIT 20;

-- Tiền thanh toán thành công theo client
SELECT *
FROM v_client_spend
ORDER BY client_id
LIMIT 20;
```

### 5.2 Thống kê trạng thái

```sql
SELECT status, COUNT(*) AS quantity
FROM mini_upwork.contracts
GROUP BY status;

SELECT status, COUNT(*) AS quantity
FROM mini_upwork.milestones
GROUP BY status;

SELECT payment_status, COUNT(*) AS quantity
FROM mini_upwork.payments
GROUP BY payment_status;
```

### 5.3 Chạy 12 truy vấn nâng cao

Mở `sql/06_queries.sql`, chọn từng truy vấn để chạy hoặc chạy toàn bộ. Mỗi SELECT có kết quả riêng. Đối chiếu với `docs/large_dataset_report.md` cho bộ dữ liệu lớn; không dùng Expected Result của bộ seed nhỏ để so trực tiếp.

## 6. Kiểm tra tự động bằng Python nếu cần

Phần này không bắt buộc để xem dữ liệu trong Workbench. Cần Python và kết nối MySQL đang chạy.

Mở PowerShell tại thư mục `G3_Database_Project`, nơi có `requirements.txt`, rồi chạy:

```powershell
python -m pip install -r requirements.txt

$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '3306'  # Thay bằng cổng thực tế; Docker đi kèm dùng 3307
$credential = Get-Credential -UserName 'root' -Message 'Nhap tai khoan MySQL'
$env:DB_USER = $credential.UserName
$env:DB_PASSWORD = $credential.GetNetworkCredential().Password

python tests/verify_large_dataset.py

Remove-Item Env:DB_PASSWORD
$credential = $null
```

Khi hộp thoại hiện ra, nhập thông tin tài khoản MySQL, không phải tài khoản Windows. Nếu lệnh `python` không được nhận diện nhưng đã cài Python Launcher, thử thay bằng `py`.

Kết quả thành công gồm `total_rows: 7223`, `zero_violation_checks: 9`, `advanced_queries_executed: 12` và `passed: true`. Script không thay đổi dữ liệu database; nó ghi lại `evidence/large_dataset_results.json` tại máy chạy.

## 7. Trình tự demo ngắn

1. Mở schema mini_upwork, cho thấy đủ 11 bảng.
2. Chạy 09_verify_counts.sql, cho thấy tổng 7.223 dòng.
3. Xem jobs, proposals, contracts, milestones và payments.
4. Chạy v_job_proposals để thấy job có/không có proposal.
5. Chạy v_contract_overview để thấy tiền hợp đồng và số tiền còn thiếu.
6. Thống kê payment_status để thấy PENDING, FAILED, PAID.
7. Chọn một truy vấn CTE/window function trong 06_queries.sql để giải thích.

Các truy vấn SELECT trong hướng dẫn chỉ đọc dữ liệu. Dữ liệu mẫu là giả lập; password_hash cố ý không dùng để đăng nhập. Ngoại lệ 3NF của PAYMENT vẫn giữ nguyên và được giải thích trong docs/normalization.md.

## 8. Tài liệu MySQL tham khảo

- [Query and Edit Menus](https://dev.mysql.com/doc/workbench/en/wb-sql-editor-main-menu.html)
- [SQL Query Toolbar](https://dev.mysql.com/doc/workbench/en/wb-sql-editor-toolbar.html)
- [SQL Query Tab](https://dev.mysql.com/doc/workbench/en/wb-sql-editor-query-panel.html)
