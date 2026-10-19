# Mini-Upwork G3 — 7.223 dòng dữ liệu

MySQL 8.0.42, InnoDB, READ COMMITTED; giữ nguyên 11 bảng nghiệp vụ.

## Cài mới bằng MySQL Workbench

1. Kết nối MySQL bằng tài khoản quản trị có quyền tạo schema, trigger, view, procedure, role và user.
2. File > Open SQL Script: mở INSTALL_DATABASE.sql.
3. Chạy toàn bộ script, dừng nếu có lỗi. Refresh Schemas > mini_upwork > Tables.
4. Chạy sql/09_verify_counts.sql: cột total_rows = 7223.
5. Chạy sql/06_queries.sql để xem 12 truy vấn trên dữ liệu mới.

File cài tổng hợp chỉ dùng với database mới. Không bỏ qua lỗi để import tiếp,
không tự xóa database đang có. Các tài khoản MySQL mẫu đều bị khóa; DBA phải
đặt bí mật riêng trước khi dùng. Ứng dụng không nên kết nối bằng root.

## Nếu đã cài 01 đến 05 với bộ seed nhỏ

Chạy riêng sql/08_seed_1000_jobs.sql, rồi sql/09_verify_counts.sql.
Không chạy lại INSTALL_DATABASE.sql hoặc 05_seed.sql trên các bảng đã có.
Extension chạy một lần, giữ seed cũ và rollback dữ liệu thêm khi gặp lỗi.
Nó từ chối nếu vùng ID sử dụng đã có dữ liệu. Nếu có dữ liệu riêng ngoài seed
nhỏ, tổng thực tế có thể khác 7223. Chạy bằng phiên DBA độc lập, READ COMMITTED.

## Kiểm thử

Cài requirements.txt, đặt DB_HOST, DB_PORT, DB_USER, DB_PASSWORD rồi chạy:

```bash
python tests/verify_large_dataset.py
```

Verifier chỉ đọc database, ghi evidence/large_dataset_results.json: kiểm tra
11 số đếm, tổng 7223, 9 invariant bằng 0 và thực thi đủ 12 advanced queries.
Expected/Actual Result cũ của bộ seed 75 dòng không áp dụng cho dữ liệu lớn.

CẢNH BÁO: tests/run_tests.py --install là bộ kiểm thử seed nhỏ có bước
DROP/rebuild mini_upwork. Không chạy nó trên database demo lớn hoặc dữ liệu
cần giữ. Nếu muốn chạy bộ nhỏ, dùng MySQL instance riêng trước khi thêm seed lớn.

## Phạm vi dữ liệu và bằng chứng

Extension thêm 1000 jobs và các tài khoản, skills, proposals, contracts,
milestones, payments liên quan. Có jobs chưa nhận proposal, đề xuất chờ chọn,
chờ xác nhận, hợp đồng ACTIVE/COMPLETED, bốn trạng thái milestone và ba trạng
thái payment. Có FAILED rồi retry PAID, không có hai PAID trên một milestone.
Subtype và contract vẫn được tạo bởi trigger, không tắt constraints.
Dữ liệu người/công ty hoàn toàn giả lập, email example.test, hash không đăng nhập.

- docs/large_dataset_report.md và evidence/large_dataset_results.json: kết quả
  thực thi mới trên 7223 dòng, 9 invariant và 12 query với 10 dòng đầu mỗi query.
- Các evidence JSON khác và audit/query/test reports ghi lần chạy seed nhỏ:
  72 integrity/concurrency checks, 20 RBAC checks, 12 query assertions; không
  phải tuyên bố chạy lại 104 checks trên seed lớn.
- Báo cáo Word không nằm trong gói. Nếu dùng dữ liệu lớn để nộp, cập nhật mục
  Synthetic data coverage và Expected/Actual Result theo large_dataset_report.md.
- PAYMENT vẫn giữ ngoại lệ 3NF đã giải thích trong normalization.md; tăng dữ liệu
  không thay đổi thiết kế. TLS, encryption at rest, backup/restore, gateway và
  UI/backend không được triển khai bởi gói này.
- 240 hồ sơ mới không tự tạo 240 tài khoản MySQL; native accounts mẫu vẫn chỉ
  dành cho localhost theo 07_security.sql.

Ít nhất 1000 dòng được hiểu là tổng các bảng, không phải mỗi bảng 1000 dòng.
Riêng bảng jobs có 1008 dòng.
