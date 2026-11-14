# Mini-Upwork G3 - Cơ sở dữ liệu MySQL và web Flask

Dự án **Freelance Marketplace Ecosystem** (hệ sinh thái kết nối khách hàng và người làm việc tự do) gồm cơ sở dữ liệu có thể cài đặt và bản mẫu web giai đoạn 4 viết bằng Flask.

Xem [hướng dẫn cài đặt và trình bày trên Windows](tutorial.md) hoặc [hướng dẫn dữ liệu mẫu](Freelance_Marketplace_Ecosystem_SQL/README.md).

## Nhóm G3

| MSSV | Họ và tên | Tài khoản GitHub |
|---|---|---|
| N25DCAT073 | Huỳnh Thiện Đức | [htduc1701](https://github.com/htduc1701) |
| N25DCAT076 | Phạm Việt Hoàng | [shinmagicc](https://github.com/shinmagicc) |
| N25DCAT079 | Đặng Quang Huy | [Kurookani](https://github.com/Kurookani) |

## 1. Môi trường và thiết kế hiện tại

- Hệ quản trị cơ sở dữ liệu: MySQL Community Server cài trên máy, cổng thường dùng là `3306`.
- Nhật ký [kiểm thử ngày 14/11/2026](audit_test_results/FRESH_TEST_RUN_2026-11-14.md) ghi nhận **84/84 phép kiểm tra đạt** trên máy chủ báo phiên bản `26.7.0`, với bộ dữ liệu cơ bản trong schema tạm. Kết quả này không xác nhận khả năng tương thích với MySQL `8.0.42`.
- Cấu hình Docker Compose tùy chọn dùng MySQL `8.0.42`, ánh xạ cổng `3307` trên máy vào cổng `3306` trong vùng chứa.
- Bộ máy lưu trữ: InnoDB.
- Mức cô lập giao dịch cho các thao tác ghi theo quy trình: `READ COMMITTED`.
- Số bảng nghiệp vụ: **11**.
- Phần máy chủ web: Flask.
- Thư viện kết nối MySQL: `mysql-connector-python` cho Flask và `PyMySQL` cho các công cụ kiểm thử.

Bảng `payments` sau chuẩn hóa chỉ lưu thông tin của từng lần ghi nhận thanh toán:

```text
payments(
    payment_id PK,
    milestone_id FK,
    payment_status,
    payment_method,
    paid_milestone_id UQ [cột sinh tự động]
)
```

`PK` là khóa chính, `FK` là khóa ngoại và `UQ` là ràng buộc duy nhất. Người trả, người nhận và số tiền được xác định qua liên kết `payments -> milestones -> contracts`.

## 2. Các tệp và thư mục quan trọng

Mã nguồn và các tệp SQL nằm trong thư mục [Freelance_Marketplace_Ecosystem_SQL](Freelance_Marketplace_Ecosystem_SQL). Các đường dẫn trong bảng dưới đây tính từ thư mục đó.

| Đường dẫn | Nội dung |
|---|---|
| `app/` | Các mẫu giao diện Flask và hàm hỗ trợ kết nối cơ sở dữ liệu |
| `main.py` | Tệp khởi chạy ứng dụng Flask |
| `sql/01_schema.sql` | Bảng, khóa và ràng buộc `CHECK` |
| `sql/02_triggers.sql` | Trigger kiểm soát quy trình và tính toàn vẹn |
| `sql/03_views_indexes.sql` | View báo cáo và chỉ mục |
| `sql/04_procedures.sql` | Các thủ tục lưu trữ phục vụ ứng dụng |
| `sql/05_seed.sql` | Bộ dữ liệu mẫu cơ bản, giả lập |
| `sql/06_queries.sql` | 12 truy vấn nâng cao |
| `sql/07_security.sql` | Vai trò và tài khoản MySQL mẫu |
| `sql/08_seed_1000_jobs.sql` | Bộ dữ liệu mở rộng thêm 1.000 công việc |
| `sql/09_verify_counts.sql` | Kiểm đếm số dòng dữ liệu |
| `INSTALL_DATABASE.sql` | Tệp cài đặt tổng hợp từ các tệp SQL thành phần |
| `SAMPLE_DATA.sql` | Tệp tổng hợp dữ liệu mẫu cơ bản và mở rộng |
| `SETUP_LOCAL_DEMO.sql` | Đặt mật khẩu mẫu và mở khóa ba tài khoản dùng để demo |
| `tests/` | Kiểm thử hồi quy, hiệu năng và dữ liệu lớn |
| `evidence/` | Bằng chứng kiểm thử đã lưu hoặc được tạo khi chạy kiểm thử |
| `docs/` | Tài liệu thiết kế và kiểm chứng |
| `requirements.txt` | Các thư viện Python cho ứng dụng và kiểm thử |
| `compose.yaml` | Cấu hình MySQL tùy chọn bằng Docker Compose |

## 3. Cài đặt cơ sở dữ liệu

### Cách A - cài đặt bằng một tệp trong MySQL Workbench

Dùng cho cơ sở dữ liệu **mới**, chưa có các bảng nghiệp vụ của dự án.

1. Mở MySQL Workbench và kết nối bằng tài khoản quản trị.
2. Mở [INSTALL_DATABASE.sql](Freelance_Marketplace_Ecosystem_SQL/INSTALL_DATABASE.sql).
3. Chạy toàn bộ tệp; dừng và kiểm tra nếu bất kỳ câu lệnh nào báo lỗi.
4. Làm mới danh sách **Schemas** để thấy schema `mini_upwork`.
5. Phần cuối tệp thực hiện nội dung của `sql/09_verify_counts.sql`. Với bộ dữ liệu mở rộng nguyên bản, kết quả dự kiến là **7.223 dòng**, trong đó có **1.008 công việc** trong bảng `jobs`.

`INSTALL_DATABASE.sql` được tổng hợp từ các tệp thành phần theo thiết kế đã chuẩn hóa. Bảng `payments` không còn các cột cũ `payer_id`, `payee_id` và `amount`.

### Cách B - cài đặt từng tệp thành phần

Trên cơ sở dữ liệu mới, chạy các tệp trong thư mục `sql/` theo thứ tự:

```text
01_schema.sql
02_triggers.sql
03_views_indexes.sql
04_procedures.sql
05_seed.sql
08_seed_1000_jobs.sql
07_security.sql
09_verify_counts.sql
```

Sau đó chạy `06_queries.sql` khi cần minh họa các truy vấn nâng cao.

**Không nạp lại** `05_seed.sql`, `08_seed_1000_jobs.sql`, `SAMPLE_DATA.sql` hoặc `INSTALL_DATABASE.sql` vào cơ sở dữ liệu demo đã có đầy đủ dữ liệu.

## 4. Tệp chỉ chứa dữ liệu mẫu

`SAMPLE_DATA.sql` tổng hợp nội dung của:

```text
sql/05_seed.sql
sql/08_seed_1000_jobs.sql
```

Chỉ dùng sau khi đã cài `01_schema.sql` đến `04_procedures.sql` và các bảng nghiệp vụ còn trống. Nếu đã chạy `INSTALL_DATABASE.sql`, không chạy thêm `SAMPLE_DATA.sql`.

## 5. Chuẩn bị môi trường Python

Từ thư mục gốc của kho mã nguồn, mở PowerShell và chạy:

```powershell
Set-Location .\Freelance_Marketplace_Ecosystem_SQL
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Nếu đã ở trong `Freelance_Marketplace_Ecosystem_SQL`, bỏ qua lệnh `Set-Location`. Các lệnh bên dưới cũng chạy tại thư mục này. Gọi trực tiếp Python trong `.venv` giúp sử dụng đúng môi trường mà không cần kích hoạt hay đổi chính sách thực thi PowerShell.

Các thư viện trong `requirements.txt`:

```text
Flask
mysql-connector-python
PyMySQL[rsa]==1.1.2
```

## 6. Chạy bản demo Flask giai đoạn 4

Khởi động dịch vụ MySQL. Sau khi cài cơ sở dữ liệu, chạy [SETUP_LOCAL_DEMO.sql](Freelance_Marketplace_Ecosystem_SQL/SETUP_LOCAL_DEMO.sql) bằng tài khoản quản trị để đặt mật khẩu mẫu và mở khóa các tài khoản demo.

Trong cửa sổ PowerShell dùng để chạy Flask, đặt thông tin kết nối:

```powershell
$env:DB_HOST = 'localhost'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$env:DB_PASSWORD = Read-Host 'Nhập mật khẩu MySQL root' -MaskInput
.\.venv\Scripts\python.exe main.py
```

Nếu PowerShell không hỗ trợ `-MaskInput`, thay dòng nhập mật khẩu bằng đoạn sau trước khi chạy `main.py`:

```powershell
$mysqlPassword = Read-Host 'Nhập mật khẩu MySQL root' -AsSecureString
$env:DB_PASSWORD = [System.Net.NetworkCredential]::new('', $mysqlPassword).Password
```

Ví dụ dùng `root` phù hợp với cấu hình demo hiện có: ứng dụng dùng `DB_USER`/`DB_PASSWORD` cho các kết nối đọc, còn thao tác ghi của Client, Freelancer và dịch vụ thanh toán dùng tài khoản riêng trong `app/db.py`.

Mở [http://127.0.0.1:5000](http://127.0.0.1:5000). Giữ cửa sổ PowerShell mở trong lúc demo; nhấn `Ctrl+C` để dừng.

Quy trình trình bày chính:

1. Khách hàng (Client) đăng công việc (Job).
2. Người làm việc tự do (Freelancer) gửi đề xuất (Proposal).
3. Khách hàng chọn đề xuất.
4. Freelancer xác nhận; hệ thống tạo hợp đồng (Contract).
5. Khách hàng tạo mốc công việc (Milestone).
6. Freelancer bắt đầu và hoàn thành công việc.
7. Khách hàng phê duyệt mốc công việc.
8. Ghi nhận thanh toán (Payment) mô phỏng.
9. Xem kết quả trên trang báo cáo.

Luồng demo chính dùng Client ID **`1`** và Freelancer ID **`4`**. Đây là bản mẫu phục vụ học tập; chức năng thanh toán chỉ ghi nhận trạng thái, không thu tiền thật.

## 7. Kiểm tra bộ dữ liệu mở rộng

Đặt biến kết nối tới MySQL chứa bộ dữ liệu mở rộng. Với MySQL cài trên máy, thường dùng cổng `3306`; với Compose của dự án, dùng cổng `3307`.

```powershell
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$env:DB_PASSWORD = Read-Host 'Nhập mật khẩu MySQL root' -MaskInput
.\.venv\Scripts\python.exe tests\verify_large_dataset.py
```

Nếu PowerShell không hỗ trợ `-MaskInput`, dùng đoạn `-AsSecureString` ở mục 6.

Số dòng dự kiến của bộ dữ liệu nguyên bản:

| Bảng | Số dòng |
|---|---:|
| `users` | 248 |
| `clients` | 43 |
| `freelancers` | 205 |
| `skills` | 26 |
| `freelancer_skills` | 610 |
| `job_categories` | 11 |
| `jobs` | 1.008 |
| `proposals` | 1.811 |
| `contracts` | 605 |
| `milestones` | 1.810 |
| `payments` | 846 |
| **Tổng** | **7.223** |

Các số này áp dụng **trước khi phát sinh dữ liệu demo**. Sau khi đăng công việc, gửi đề xuất hoặc ghi nhận thanh toán, số dòng thực tế có thể tăng và chương trình kiểm tra số lượng cố định sẽ báo khác kỳ vọng.

Chương trình kiểm tra dùng bảng `payments` đã chuẩn hóa và đối chiếu trạng thái thanh toán, công việc. Chương trình chỉ đọc cơ sở dữ liệu nhưng ghi kết quả vào `evidence/large_dataset_results.json`.

## 8. Chạy bộ kiểm thử hồi quy

**Cảnh báo:** `tests/run_tests.py --install` có bước xóa và tạo lại schema `mini_upwork`. Chỉ chạy trên một MySQL instance riêng dùng cho kiểm thử, không chứa dữ liệu cần giữ. Chạy không có `--install` vẫn có thể thay đổi dữ liệu trong các ca kiểm thử; không dùng trên cơ sở dữ liệu demo cần bảo toàn.

Ví dụ dưới đây giả sử instance kiểm thử riêng lắng nghe ở cổng `3307`; thay bằng đúng cổng của instance đó. Dùng một cổng khác không tự bảo đảm dữ liệu đã được cô lập.

```powershell
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '3307'
$env:DB_USER = 'root'
$env:DB_PASSWORD = Read-Host 'Nhập mật khẩu MySQL kiểm thử' -MaskInput
.\.venv\Scripts\python.exe tests\run_tests.py --install
```

Nếu PowerShell không hỗ trợ `-MaskInput`, dùng đoạn `-AsSecureString` ở mục 6 với mật khẩu của instance kiểm thử.

Để chạy thêm kiểm tra phân quyền theo vai trò (RBAC) bằng tài khoản MySQL:

```powershell
.\.venv\Scripts\python.exe tests\run_tests.py --install --security
```

Các tệp bằng chứng được ghi lại trong quá trình chạy:

| Tệp | Nội dung |
|---|---|
| `evidence/test_results.json` | Kết quả kiểm tra tính toàn vẹn và quy trình |
| `evidence/query_results.json` | Kết quả kiểm tra truy vấn |
| `evidence/security_results.json` | Kết quả phân quyền khi có `--security` |
| `evidence/environment.json` | Thông tin môi trường kiểm thử |

Chỉ đổi trạng thái báo cáo từ **Chưa chạy lại (Not rerun)** sang **Đạt (PASS)** khi lần chạy tương ứng trên phiên bản hiện tại đã thành công và có bằng chứng được lưu. Kết quả 84/84 ở mục 1 không bao gồm bộ RBAC, kiểm thử dữ liệu lớn hay hiệu năng.

## 9. Kiểm thử hiệu năng

Sau khi đặt biến kết nối cho instance kiểm thử, chạy chương trình tùy chọn dùng PyMySQL:

```powershell
.\.venv\Scripts\python.exe tests\run_performance.py
```

Các số đo hiệu năng cũ trong báo cáo là kết quả đã lưu từ lần chạy trước. Cần chạy lại nếu muốn có bằng chứng đo mới.

## 10. Bảo mật và phạm vi đề tài

- Các thao tác ghi của ứng dụng sử dụng thủ tục lưu trữ và quy tắc nghiệp vụ trong cơ sở dữ liệu.
- `payment_service` là tài khoản ứng dụng được thiết kế để gọi `sp_record_payment`.
- Các vai trò ứng dụng thông thường của Client, Freelancer và dịch vụ thanh toán không được cấp quyền sửa dữ liệu trực tiếp trên bảng.
- Bản mẫu Flask giai đoạn 4 phục vụ trình bày trên lớp, chưa phải hệ thống xác thực và thanh toán để triển khai thực tế.
- Các chức năng ngoài phạm vi: ký quỹ, hoàn tiền, thu tiền qua cổng thanh toán thật, bảo đảm yêu cầu thanh toán lặp không bị xử lý trùng tại nhà cung cấp, khôi phục mật khẩu, nhắn tin và thuật toán ghép nối.
- Không đưa mật khẩu thật hoặc thông tin truy cập dịch vụ thanh toán thực tế lên kho mã nguồn.

## 11. Nội dung đề nghị đưa vào bài nộp

Giữ các thành phần sau trong thư mục mã nguồn:

```text
app/
docs/
evidence/
sql/
tests/
main.py
requirements.txt
README.md
compose.yaml
INSTALL_DATABASE.sql
SAMPLE_DATA.sql
SETUP_LOCAL_DEMO.sql
```

Kèm README ở thư mục gốc, `tutorial.md` và báo cáo Word khi đóng gói toàn bộ bài nộp. Không đưa `.venv/`, `__pycache__/`, `*.pyc` hoặc `.git/` vào tệp ZIP nộp bài.
