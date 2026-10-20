# Báo cáo cơ sở dữ liệu G3 đã chỉnh sửa

Bản kết quả ngày 20/10/2026. Báo cáo chính viết tiếng Anh và kế thừa bài cũ của nhóm. Mọi sản phẩm mới nằm trong thư mục này; bài gốc bên ngoài `G3_RaSoat_HoanThien_2026-10-20` được giữ nguyên.

## Đọc và nộp

- `Bao_cao_G3_Hoan_thien.docx`: bản có thể chỉnh sửa.
- `Bao_cao_G3_Hoan_thien.pdf`: bản xuất để kiểm tra và nộp nếu thầy nhận PDF.
- `database/`: SQL cuối, dữ liệu, dictionary và chương trình kiểm thử mới.
- `diagrams/`: nguồn Graphviz `.dot`, hình SVG/PNG; sơ đồ dùng compartment và multiplicity UML.
- `app/`: demo web local bằng Python và PyMySQL.
- `evidence/`: bằng chứng mới, không dùng kết quả PASS của schema cũ.
- `Doi_chieu_yeu_cau.md`, `Nhat_ky_thay_doi.md`: ghi chú kiểm tra nội bộ, tách khỏi báo cáo nộp.
- `Huong_dan_demo_va_bao_ve.md`: thực hành và phần nhóm cần tự xác nhận.

Nộp báo cáo và mã nguồn theo cách thầy yêu cầu. Không cần nộp `_work/` ở thư mục cha: đó là môi trường build, database kiểm thử riêng và ảnh kiểm tra bố cục.

## Những thay đổi chính

1. Chuẩn hóa `payments`: chỉ còn attempt ID, milestone ID, trạng thái và phương thức; view suy ra số tiền/người trả/người nhận từ các điều khoản bất biến.
2. Thêm `contract_reviews`: một client đánh giá freelancer sau khi hợp đồng hoàn tất, điểm 1–5; có tổng hợp số lượt và trung bình, không cho đánh giá trùng.
3. Chuyển conditional uniqueness sang functional index, không thêm cột tính toán vào logical relation.
4. Giữ dữ liệu giả lập cũ, thêm 120 đánh giá: cài mới có **12 bảng, 7.343 dòng**.
5. Có **15 truy vấn**, **5 view**, **9 procedure**; số trigger xem metadata và báo cáo.
6. Thêm demo gọi procedure bằng tài khoản MySQL theo vai trò.

## Môi trường đã thực sự kiểm chứng

MySQL Community Server **26.7.0** trên Windows, InnoDB, READ COMMITTED; instance riêng tại loopback port 33370. **59 checks PASS, 0 FAIL**, 15 truy vấn thực thi được, bao gồm 10 invariant toàn dữ liệu, một lịch ghi ngân sách đồng thời và HTTP đọc/ghi DB. Chi tiết, SQL, lỗi kỳ vọng/thực tế và thời gian chạy trong `evidence/`.

SQL dùng tính năng từ MySQL 8.0.16 trở lên, gồm CHECK và functional index; **chưa chạy xác nhận trên MySQL 8.0 trong lần sửa này**. Không đổi nhãn bằng chứng 26.7 thành 8.0.42. Bộ kiểm thử thêm bản ghi sau khi đếm fixture, nên output query có thể chứa nhiều dòng hơn fixture mới cài.

## Cài database

Chỉ sử dụng instance/schema dành riêng cho demo. Không chạy bộ cài hoặc kiểm thử vào dữ liệu nhóm cần giữ. Tài khoản cài cần quyền tạo database, table, trigger, view, routine, role, account và phân quyền. Script không tự DROP DATABASE; có thể đã tạo một phần đối tượng nếu lần cài bị lỗi, vì DDL không rollback như DML. Khi đó dùng một instance rỗng mới để tái lập.

Trong MySQL client hoặc Workbench, kết nối server demo và chạy **một lần**:

```sql
SOURCE D:/csdl/csdl_G3/G3_RaSoat_HoanThien_2026-10-20/ket_qua/database/INSTALL_DATABASE.sql;
```

`SOURCE` là lệnh của mysql CLI; với Workbench hãy mở file và chạy script đầy đủ.

Đường cài module tương đương: **01 → 02 → 03 → 04 → 05 → 08 → 10 → 07 → 09** trong `database/sql/`. Module 06 chứa truy vấn, chạy sau khi cài.

Không chạy tiếp `SAMPLE_DATA.sql` sau INSTALL. Data-only là lựa chọn khác khi đã cài 01–04 và các bảng nghiệp vụ còn trống; nó chứa 05 + 08 + 10. Không trộn seed cũ với seed mới.

```sql
USE mini_upwork;
SELECT COUNT(*) FROM contract_reviews; -- 120 sau cài mới
-- Chạy sql/09_verify_counts.sql để xem đủ 12 bảng, tổng 7343.
```

## Chạy kiểm thử mới

Cài dependency bằng Python phù hợp của bạn:

```powershell
python -m pip install -r .\database\requirements.txt
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '33370'
$env:DB_USER = 'root'
$env:DB_PASSWORD = [Net.NetworkCredential]::new('', (Read-Host 'Test DB password' -AsSecureString)).Password
python .\database\tests\verify_project.py
```

Chạy từ `ket_qua`. Khi schema hoàn toàn rỗng, có thể dùng `--fresh-install` để vừa cài vừa kiểm thử. Chương trình từ chối cài mới nếu schema đã có bảng. Không chạy lại trên instance đã kiểm thử; bộ test không idempotent.

**Verifier có ghi dữ liệu**, tạo bản ghi workflow, đổi mật khẩu ngẫu nhiên và mở khóa tạm các tài khoản demo, sau đó khóa lại khi hoàn tất. Chỉ dùng instance bỏ được với quyền DBA; không phải công cụ kiểm tra chỉ đọc. Nếu chương trình bị ngắt giữa chừng, bỏ instance kiểm thử hoặc khóa các account trước khi dùng lại. Evidence cũ trong gói sẽ bị thay bằng kết quả lần chạy mới, vì vậy sao lưu nếu muốn giữ nhiều lần đo.

Không chạy runner cũ từ folder gốc lên database mới: schema payments đã thay đổi và runner cũ có lệnh DROP DATABASE. Bằng chứng gốc vẫn nằm nguyên ở folder dự án cũ để đối chiếu, không nằm lẫn trong evidence mới.

## Chạy ứng dụng

DBA đặt mật khẩu riêng và mở khóa ba tài khoản demo trong MySQL. Thay giá trị minh họa trước khi chạy, không lưu mật khẩu thật vào Git:

```sql
ALTER USER 'client_1'@'localhost' IDENTIFIED BY '<your-private-client-secret>' ACCOUNT UNLOCK;
ALTER USER 'freelancer_4'@'localhost' IDENTIFIED BY '<your-private-freelancer-secret>' ACCOUNT UNLOCK;
ALTER USER 'payment_service'@'localhost' IDENTIFIED BY '<your-private-payment-secret>' ACCOUNT UNLOCK;
```

```powershell
python -m pip install -r .\app\requirements.txt
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '33370'
$env:APP_PORT = '8086'
python .\app\server.py
```

Mở `http://127.0.0.1:8086`, đăng nhập bằng một trong ba tài khoản MySQL trên. Dùng cửa sổ private/profile riêng cho từng vai trò. Không đăng nhập bằng root; app từ chối root. `.env.example` chỉ mô tả biến, app không tự đọc file `.env`.

App chỉ phục vụ demo trên máy cá nhân: HTTP Basic trên loopback, không phải hệ thống đăng nhập để public. Các tài khoản demo có quyền đọc aggregate views toàn hệ thống; báo cáo không cam kết cách ly báo cáo giữa các client. Không có giao dịch tiền thật, gateway, escrow hay refund.

## Cần nhóm thực hiện trước khi nộp

- Kiểm tra tên nhóm, thành viên, yêu cầu hình thức riêng nếu thầy có bổ sung.
- Chạy lại trên đúng phiên bản MySQL và máy dùng để bảo vệ nếu khác môi trường đã đo.
- Thực hành chuyển vai trò, lấy ID và luồng demo trong hướng dẫn.
- Xác nhận phân công thực tế, peer evaluation và tự thực hiện live presentation/SQL defense. Gói không tự điền điểm hoặc khẳng định những hoạt động đó đã hoàn thành.
- TLS remote, encryption at rest, backup/restore và SLA production là các yêu cầu triển khai chưa được chứng minh trong lần làm này.
