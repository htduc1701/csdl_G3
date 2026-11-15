# Mini-Upwork G3 - Synthetic Sample Dataset

See the [main README](../README.md) and the [Windows setup guide](../tutorial.md) to run the Flask application and demonstrate the Client-Freelancer workflow.

<<<<<<< Updated upstream
Paths below are relative to `Freelance_Marketplace_Ecosystem_SQL`.

## 1. Environment and Dataset

=======
<<<<<<< HEAD
Môi trường demo: MySQL Community Server 26.7.0 cài local, cổng 3306, InnoDB, READ COMMITTED; 11 bảng nghiệp vụ. Bộ test dữ liệu cơ bản đạt 104/104 trên 26.7.0, gồm 20 ca phân quyền.
=======
Paths below are relative to `Freelance_Marketplace_Ecosystem_SQL`.
>>>>>>> 3553ad1a7c2a8b36807001aa564cc991840e958b

## 1. Environment and Dataset

<<<<<<< HEAD
1. Kết nối MySQL bằng tài khoản quản trị có quyền tạo schema, trigger, view, procedure, role và user.
2. File > Open SQL Script: mở INSTALL_DATABASE.sql.
3. Chạy toàn bộ script, dừng nếu có lỗi. Refresh Schemas > mini_upwork > Tables.
4. Phần kiểm đếm cuối file dự kiến cho 748 user (143 client, 605 freelancer) và total_rows = 8223. Có thể chạy lại sql/09_verify_counts.sql để xem số đếm.
5. Chạy sql/06_queries.sql để xem 12 truy vấn trên dữ liệu mới.
=======
>>>>>>> Stashed changes
- MySQL with InnoDB; `READ COMMITTED` isolation for workflow write operations.
- **11 business tables**, containing **7,223 records**, including **1,008 jobs**.
- The expanded dataset adds 1,000 jobs to the base sample dataset.
- People and companies are fictional; email addresses use `example.test`; monetary amounts are in USD. Descriptions and skills are assembled across eight professional categories. This is template-generated data, not real transactions or data collected from real people.
- The local installation uses MySQL Community Server `26.7.0` on port `3306`.
<<<<<<< Updated upstream
=======
>>>>>>> 3553ad1a7c2a8b36807001aa564cc991840e958b
>>>>>>> Stashed changes

## 2. Fresh Installation with MySQL Workbench

1. Connect to MySQL with an administrative account authorized to create schemas, triggers, views, stored procedures, roles, and accounts.
2. Select **File > Open SQL Script** and open [INSTALL_DATABASE.sql](INSTALL_DATABASE.sql).
3. Run the entire script, stopping if any error occurs. Refresh **Schemas > mini_upwork > Tables**.
4. The final section already verifies row counts; you can rerun [sql/09_verify_counts.sql](sql/09_verify_counts.sql). For the original dataset, `total_rows` is **7,223**.
5. Run [SETUP_LOCAL_DEMO.sql](SETUP_LOCAL_DEMO.sql) as an administrator to use the web application with Client ID **1** and Freelancer ID **4**.
6. Run [sql/06_queries.sql](sql/06_queries.sql) to view the 12 advanced queries.

<<<<<<< Updated upstream
The installation bundle is intended for a fresh database only. Do not ignore errors and continue importing. Sample MySQL accounts are created in a locked state by `07_security.sql`; `SETUP_LOCAL_DEMO.sql` sets sample passwords matching `app/db.py` and unlocks the three accounts used for the local demo.

## 3. Importing Sample Data Separately

[SAMPLE_DATA.sql](SAMPLE_DATA.sql) contains `INSERT ... VALUES` statements with fictional people, companies, professional titles, jobs, proposals, and milestones.

Run it only after installing `sql/01_schema.sql` through `sql/04_procedures.sql` while the business tables are empty. It already includes both `05_seed.sql` and `08_seed_1000_jobs.sql`; do not load it again if `INSTALL_DATABASE.sql` has been used.

## 4. Extending the Base Dataset
=======
<<<<<<< HEAD
SAMPLE_DATA.sql chứa các bản ghi INSERT ... VALUES cụ thể như file
dữ liệu video game: tên người Việt, công ty, chức danh, job, proposal và milestone.
File này chỉ chạy sau sql/01_schema.sql đến sql/04_procedures.sql trên các bảng
nghiệp vụ còn trống. File gộp hai seed 05 và 08. Seed 08 cũng tạo thêm 500 user. Chọn chạy SAMPLE_DATA.sql
hoặc INSTALL_DATABASE.sql theo cách cài ở trên. Dự kiến có 8223 bản ghi,
gồm 748 user và 1008 công việc tên khác nhau.
Tên và công ty đều giả lập; email example.test; tiền trong dữ liệu mẫu tính bằng USD.
Mô tả và kỹ năng được ghép theo 8 nhóm chuyên môn; vẫn là dữ liệu sinh theo mẫu,
không phải giao dịch thật hay dữ liệu thu thập từ người thật.
=======
The installation bundle is intended for a fresh database only. Do not ignore errors and continue importing. Sample MySQL accounts are created in a locked state by `07_security.sql`; `SETUP_LOCAL_DEMO.sql` sets sample passwords matching `app/db.py` and unlocks the three accounts used for the local demo.
>>>>>>> 3553ad1a7c2a8b36807001aa564cc991840e958b

## 3. Importing Sample Data Separately

<<<<<<< HEAD
Chạy sql/08_seed_1000_jobs.sql rồi sql/09_verify_counts.sql. Nếu đã nạp bộ 1.000 job, chỉ bôi đen và chạy khối từ `BEGIN additional 500 user profiles` đến `END additional 500 user profiles` trong file 08. Khối này bỏ qua email đã tồn tại.
Không chạy lại INSTALL_DATABASE.sql hoặc 05_seed.sql trên các bảng đã có.
Extension chạy một lần, giữ seed cũ (không đổi tên Demo trong seed cũ) và rollback dữ liệu thêm khi gặp lỗi.
Nó từ chối nếu vùng ID sử dụng đã có dữ liệu. Nếu có dữ liệu riêng ngoài seed
nhỏ, tổng thực tế có thể khác 8223. Chạy bằng phiên DBA độc lập, READ COMMITTED.
=======
[SAMPLE_DATA.sql](SAMPLE_DATA.sql) contains `INSERT ... VALUES` statements with fictional people, companies, professional titles, jobs, proposals, and milestones.
>>>>>>> 3553ad1a7c2a8b36807001aa564cc991840e958b

Run it only after installing `sql/01_schema.sql` through `sql/04_procedures.sql` while the business tables are empty. It already includes both `05_seed.sql` and `08_seed_1000_jobs.sql`; do not load it again if `INSTALL_DATABASE.sql` has been used.

<<<<<<< HEAD
Sau khi nạp đủ dữ liệu mẫu và trước khi thêm dữ liệu demo, cài requirements.txt, đặt DB_HOST, DB_PORT, DB_USER, DB_PASSWORD rồi chạy. Cổng mặc định là 3306 cho MySQL local.
=======
## 4. Extending the Base Dataset
>>>>>>> 3553ad1a7c2a8b36807001aa564cc991840e958b
>>>>>>> Stashed changes

If `01_schema.sql` through `05_seed.sql` are already installed, run only [sql/08_seed_1000_jobs.sql](sql/08_seed_1000_jobs.sql), followed by [sql/09_verify_counts.sql](sql/09_verify_counts.sql).

Do not rerun `INSTALL_DATABASE.sql` or `05_seed.sql` on populated tables. The extension runs once, preserves the existing dataset, and rolls back added data if an error occurs. It refuses to run if its intended ID ranges are already occupied.

If custom data exists beyond the base dataset, or demo actions have already been performed, the actual total may differ from 7,223. Run the extension in a separate administrative session with `READ COMMITTED` isolation.

## 5. Verifying the Expanded Dataset

Create a Python environment and install dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

<<<<<<< Updated upstream
Set the connection details and run the verifier. Use port `3306` for local MySQL `26.7.0`.
=======
<<<<<<< HEAD
Verifier chỉ đọc database và ghi evidence/install_database_results.json khi tất cả kiểm tra đạt. Nó kiểm tra
11 số đếm, tổng 8223, 9 invariant bằng 0, 5 kiểm tra nội dung dữ liệu và thực thi đủ 12 advanced queries.
Expected/Actual Result cũ của bộ seed 75 dòng không áp dụng cho dữ liệu lớn.
=======
Set the connection details and run the verifier. Use port `3306` for local MySQL `26.7.0`.
>>>>>>> 3553ad1a7c2a8b36807001aa564cc991840e958b
>>>>>>> Stashed changes

```powershell
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$mysqlPassword = Read-Host 'Enter the MySQL root password' -AsSecureString
$env:DB_PASSWORD = [System.Net.NetworkCredential]::new('', $mysqlPassword).Password
.\.venv\Scripts\python.exe tests\verify_large_dataset.py
```

The verifier only reads the database and writes results to `evidence/large_dataset_results.json`. It checks row counts for all 11 tables, the 7,223-row total, nine integrity conditions with zero violations, five data-content checks, and execution of all 12 advanced queries.

Expected and actual results for the 75-row base dataset do not apply to the large dataset. The fixed-count verifier may report a mismatch after demo data has been added.

<<<<<<< Updated upstream
**Warning:** `tests/run_tests.py --install` targets the base dataset and includes dropping and rebuilding the `mini_upwork` schema. Run it only on a separate MySQL instance dedicated to testing. Running without `--install` can still change data during test cases; do not run it on a demo database that must be preserved.

=======
<<<<<<< HEAD
- [Số đếm dự kiến của bản cài hiện tại](evidence/install_database_expected_counts.json) gồm 748 user và 8223 dòng trên 11 bảng.
- docs/large_dataset_report.md và evidence/large_dataset_results.json lưu kết quả
  thực thi trên bộ dữ liệu 7223 dòng, 9 invariant và 12 query với 10 dòng đầu mỗi query.
- Ngày 15/11/2026, [bộ kiểm thử dữ liệu cơ bản](../audit_test_results/verification_2026-11-15/verification_summary.json) đạt 104/104 và [bản cài sạch](evidence/install_database_results.json) xác nhận 8223 dòng trên MySQL 26.7.0.
- Báo cáo Word không nằm trong gói. Nếu dùng dữ liệu lớn để nộp, cập nhật mục
  Synthetic data coverage và Expected/Actual Result theo large_dataset_report.md.
- Tăng dữ liệu không thay đổi thiết kế PAYMENT. Web Flask có trong gói này.
  Luồng thanh toán chỉ ghi nhận trạng thái mô phỏng.
- Hồ sơ nghiệp vụ nằm trong bảng `users`. Các tài khoản kết nối MySQL cho demo
  được định nghĩa riêng trong `07_security.sql` và giới hạn ở localhost.

Yêu cầu là ít nhất 1000 bản ghi dữ liệu. Bộ seed hiện tại có 1008 công việc và dự kiến tổng cộng 8223 bản ghi.
=======
**Warning:** `tests/run_tests.py --install` targets the base dataset and includes dropping and rebuilding the `mini_upwork` schema. Run it only on a separate MySQL instance dedicated to testing. Running without `--install` can still change data during test cases; do not run it on a demo database that must be preserved.

>>>>>>> Stashed changes
## 6. Data Coverage and Recorded Results

The dataset includes jobs without proposals, proposals awaiting selection or confirmation, contracts in `ACTIVE`/`COMPLETED` states, four milestone states, and three payment states.

It includes a `FAILED` payment followed by a successful `PAID` retry, without two `PAID` payments for the same milestone. Subtype records and contracts are still created by triggers; constraints remain enabled.

- [docs/large_dataset_report.md](docs/large_dataset_report.md) and [evidence/large_dataset_results.json](evidence/large_dataset_results.json) contain evidence from a previous large-dataset verification run.
- The [test log dated November 14, 2026](../audit_test_results/FRESH_TEST_RUN_2026-11-14.md) records 72 passing integrity, workflow, and concurrency checks plus 12 passing query-result assertions, totaling **84/84**, on a server reporting version `26.7.0` using the base dataset in a disposable schema. That run excludes RBAC, large-dataset, and performance tests.
- Other evidence files may refer to older datasets or environments; they do not establish that every suite has been rerun on the large dataset.
- Expanding the dataset does not change the normalized `payments` design. The web payment workflow only records simulated statuses.
- The 240 additional profiles do not automatically create 240 MySQL accounts. Sample MySQL accounts remain restricted to `localhost` as defined in `sql/07_security.sql`; fictional profiles do not provide actual login access.

Record counts refer to rows stored in tables, not lines of SQL text.
<<<<<<< Updated upstream
=======
>>>>>>> 3553ad1a7c2a8b36807001aa564cc991840e958b
>>>>>>> Stashed changes
