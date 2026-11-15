# Kiểm định dự án Freelance Marketplace Ecosystem G3

Ngày kiểm định **15/11/2026**. Phạm vi gồm cây làm việc tại Git HEAD **a7f2eab** và năm file đã có chỉnh sửa cục bộ trước khi kiểm định. SQL kiểm thử được lấy từ cây làm việc, gồm 500 user viết trực tiếp trong seed 08. Bản cài được chạy có SHA-256 **dffe0a289f34da6738bc15667f7f364eec3b6883749f750d62ff899fe2dda8ac**.

Trạng thái dùng trong báo cáo gồm **Verified** (có bằng chứng), **Partially Verified** (mới xác minh một phần), **Failed** (kiểm tra thấy không đạt), **Not Verified** (chưa xác minh), **Not Applicable** (ngoài tiêu chí đang xét). Mọi thử nghiệm ghi dữ liệu diễn ra trên MySQL tạm mới, có datadir riêng và cổng loopback ngẫu nhiên. Báo cáo Word, mã nguồn, SQL, bằng chứng có sẵn và dịch vụ MySQL thường dùng được giữ nguyên.

## A. Executive Summary

- **Verified** · Bản cài tổng hợp, bộ modular và đường cài schema rồi chạy SAMPLE_DATA tạo cùng **8.223 bản ghi trên 11 bảng**. Ghi nhận **748 users**, trong đó 143 clients và 605 freelancers, và **1.008 jobs**. Dải ID 21201–21700 có đúng **100 clients và 400 freelancers**. Verifier đạt 9 điều kiện toàn vẹn, chạy được 12 truy vấn.
- **Verified** · Hồi quy fixture cơ bản **104/104**, gồm 72 kiểm tra SQL nghiệp vụ/toàn vẹn/đồng thời, 12 kiểm tra kết quả truy vấn và 20 kiểm tra quyền. Cả hai lượt runtime báo MySQL **26.7.0**, InnoDB và READ COMMITTED.
- **Verified** · Flask test client render các trang chính và đi trọn Client 1 / Freelancer 4 từ tạo job đến ghi payment. MySQL chặn thanh toán trước APPROVED và chặn hai payment PAID cho cùng milestone. **Failed** · Gửi trùng proposal trả HTTP 500 dù DB chặn đúng và giữ đúng một proposal.
- **Failed** · Khi DBA hoàn thành một hợp đồng đã trả đủ, job liên kết vẫn IN_PROGRESS. UPDATE tiếp theo có thể tăng giá trị hợp đồng COMPLETED, tạo chênh lệch với proposal đã chốt và phát sinh số tiền còn thiếu trong báo cáo.
- **Failed** · Hai README có 50 dấu xung đột Git, tài liệu mô tả sai Compose, và metadata/sơ đồ Markdown còn cột hay quan hệ PAYMENT cũ. Word dùng thiết kế PAYMENT mới và có ghi chú về số liệu lịch sử trong §4.2. Một số câu mô tả cần phân biệt rõ ví dụ lịch sử và kết quả hiện tại.
- Có thể diễn tập luồng chuẩn trên môi trường tạm theo mục H. Việc chấm live demo vẫn phụ thuộc thao tác trình duyệt/Workbench khi trình bày. Mức tin cậy cao với bộ SQL vừa chạy, lỗi SQL và lỗi HTTP đã tái hiện. Phiên bản Compose, máy khác và điểm cá nhân chưa xác minh.

## B. Project Architecture

~~~text
csdl_G3/
├─ Freelance_Marketplace_Ecosystem_G3.docx       yêu cầu BR/FR/NFR, EER, dictionary, truy vấn, phân quyền
├─ Workflow_Thuyet_trinh_va_Bao_ve_SQL_G3.docx   kịch bản SQL, câu phản biện, phân vai gợi ý
├─ README.md / tutorial.md / audit_report_3NF.md
├─ audit_test_results/                         nhật ký cũ, snapshot 14/11, JSON hồi quy 15/11
└─ Freelance_Marketplace_Ecosystem_SQL/
   ├─ INSTALL_DATABASE.sql / SAMPLE_DATA.sql    bundle cài đầy đủ / nạp dữ liệu
   ├─ SETUP_LOCAL_DEMO.sql                      mở ba account demo sau khi cài
   ├─ sql/01–09                                schema, trigger, view/index, routine, seed, query, quyền, scale, count
   ├─ main.py / app/db.py / app/templates/       Flask routes, kết nối, 12 giao diện Jinja
   ├─ tests/                                   hồi quy, verifier mở rộng, benchmark
   ├─ docs/                                    BR, metadata, sơ đồ, catalog, audit và báo cáo truy vấn
   ├─ evidence/                                kết quả nhiều lần chạy và số đếm chuẩn
   └─ compose.yaml / requirements*.txt         MySQL tùy chọn, thư viện app và tài liệu
~~~

Đã lập danh mục 97 đường dẫn Git theo dõi trước khi tạo báo cáo. Cây trên gom các snapshot, mẫu HTML và artifacts có cùng vai trò. .git, .venv và cache Python là metadata/môi trường cục bộ. Các nguồn thiết kế có thể đối chiếu gồm sơ đồ trong Word và docs/physical_schema.mmd.

~~~text
Biểu mẫu HTML → Flask main.py → app/db.py → MySQL mini_upwork
                                      ├─ kết nối cấu hình cho SELECT, JOIN và views
                                      └─ kết nối account Client/Freelancer/Payment cho CALL
                                           → procedure + trigger + FK/CHECK/UNIQUE
HTML Jinja ← kết quả SELECT hoặc thông báo sau thao tác
~~~

Stack chạy thử dùng Python 3.13, Flask, mysql-connector-python và PyMySQL cho test. MySQL cung cấp InnoDB, collation utf8mb4_0900_ai_ci, SQL mode nghiêm ngặt; procedure ghi có transaction ngắn, khóa hàng cha và READ COMMITTED. README và tutorial mô tả port 3306 cho dịch vụ local, port Compose thật xem D-01.

## C. Rubric Scorecard

Rubric cấp trong yêu cầu chỉ có trọng số theo nhóm. Dải ước tính bên dưới cân theo mức bao phủ quy tắc/ánh xạ, bằng chứng 3NF/BCNF, hành vi MySQL và khả năng vận hành demo. Những điểm được chứng minh được liệt kê dưới bảng. Dải số là ước tính khi chấm sản phẩm hiện tại.

| Tiêu chí | Tối đa | Điểm đề xuất | Trạng thái | Bằng chứng và rủi ro mất điểm |
|---|---:|---:|---|---|
| Data Modeling Accuracy | 25 | 20–22 | Partially Verified | 11 thực thể, khóa/subtype, BR-01–16 có đường triển khai; EER và metadata mâu thuẫn, vòng đời sau xác nhận chưa khép kín. |
| Normalization & Optimization | 15 | 12–14 | Partially Verified | FD của quan hệ logic, tách facts PAYMENT, index kiểm chứng qua plan; cần làm rõ bất biến CONTRACT và phạm vi tuyên bố chuẩn hóa. |
| SQL Technical Rigor | 20 | 16–18 | Partially Verified | Cài sạch, 104 ca đạt, 5 ca đồng thời, giải thích các CHECK/FK/UNIQUE; có ca ngoài regression làm lệch CONTRACT. |
| System Functionality | 10 | 7–8 | Partially Verified | Luồng Flask→DB hoạt động; lỗi 500 khi trùng proposal, bước mở khóa và giới hạn tài khoản demo; thao tác trình duyệt trực tiếp chưa xác minh. |
| **Group Score** | **70** | **55–62** | **Ước tính** | Không có thang chi tiết để quy đổi từng bằng chứng thành điểm chính thức. |
| Individual SQL Defense | 15 | TBD | Not Verified | Có tài liệu luyện, cần quan sát từng người viết/giải thích SQL. |
| Peer Evaluation | 15 | TBD | Not Verified | Có dấu vết commit, cần tự đánh giá và xác nhận của nhóm/giảng viên. |
| **Individual Score** | **30** | **TBD** | **Chưa xác định** | Không suy điểm từ số commit. |
| **Tổng** | **100** | **Chưa xác định** | | Điểm nhóm ở trên để tham khảo. |

Bằng chứng đã xác minh gồm ánh xạ PK/FK cho 11 bảng, các FD được nêu ở mục F, kết quả mới ở mục G và tuyến tích hợp ở mục H. Phần đánh giá chính thức của giảng viên, khả năng trả lời của từng sinh viên và đánh giá đồng cấp chưa có điểm xác định.

## D. Detailed Findings

| ID · Mức độ | Tệp/vị trí · Rubric | Bằng chứng, nguyên nhân và tác động | Khắc phục đề xuất · Chắc chắn · Phê duyệt |
|---|---|---|---|
| D-01 · HIGH | README gốc dòng 31–44, 122–173, 325–354; README gói dòng 5–35, 98–169; compose.yaml dòng 3–10 · Functionality/SQL | 24 và 26 dòng marker xung đột. Hướng dẫn có 7.223 và 8.223, 84/84 và 104/104. Compose thực tế pin 8.0.42, host 3307 → container 3306; một số đoạn nói 26.7.0 hoặc host 3306. Người đọc có thể nạp sai fixture hoặc kiểm thử nhầm dịch vụ. | Giải quyết hai conflict, ghi runtime đã chạy và môi trường Compose đúng theo YAML, ưu tiên tutorial cho local. Verified; cần đồng ý trước khi sửa. |
| D-02 · HIGH | sql/02_triggers.sql dòng 123–141, 157–197; tests/verify_large_dataset.py, bad_contract_parties · Modeling/SQL | Sau khi tạo contract từ proposal 500 và trả đủ 500, chuyển contract sang COMPLETED thành công. UPDATE DBA tăng total_amount 500→501 thành công; proposal vẫn 500, view trả paid 500/outstanding 1. Trigger kiểm tra terms lúc INSERT; khi UPDATE không khóa total_amount và chỉ kiểm tra điều kiện hoàn tất lúc đổi status. Verifier quy định amount hai bảng phải bằng nhau. | Xác nhận terms có được sửa sau khi ký không. Nếu cố định, chặn thay đổi total_amount và các thuộc tính terminal cần bất biến, bổ sung ca regression. Verified; cần đồng ý trước khi đổi luật/SQL. |
| D-03 · MEDIUM | sql/02_triggers.sql dòng 144–197; sql/08_seed_1000_jobs.sql dòng 8314–8315; main.py · Modeling/Functionality | Runtime contract 606 sang COMPLETED, job 23001 vẫn IN_PROGRESS. Trigger chỉ đổi job khi xác nhận. Seed mở rộng tự cập nhật hai bảng riêng, web kết thúc ở PAID. Word mô tả trạng thái từng bảng nhưng chưa có quy tắc chuyển đồng bộ đủ rõ. | Xác nhận job phải theo lifecycle contract hay theo vòng đời riêng, sau đó làm rõ tài liệu hoặc thiết kế một đường cập nhật transaction phù hợp. Quan sát Verified; nghĩa nghiệp vụ Partially Verified; cần đồng ý. |
| D-04 · HIGH | docs/schema_metadata.json khóa payments; docs/physical_schema.mmd các cạnh cuối; docs/business_rules.json BR-16; Word §2/3.11; sql/01_schema.sql từ dòng 137 · Modeling/Normalization | Metadata còn payer_id, payee_id, amount. Mermaid còn hai cạnh vật lý USER→PAYMENT; BR JSON dùng payer/payee như thông tin ghi trực tiếp. Word và DDL hiện dẫn xuất ba giá trị qua MILESTONE/CONTRACT. EER nhúng cạnh USER–CLIENT và USER–FREELANCER ghi 1:1, trong khi văn bản rõ 0..1 theo từng subtype. | Chốt BR-16 theo mô hình attempt và dẫn xuất, cập nhật sơ đồ/metadata, dùng ký hiệu 0..1 riêng và total/disjoint trên hợp subtype. Verified; cần đồng ý trước khi sửa cả Word. |
| D-05 · MEDIUM | main.py dòng 175–213; sql/01_schema.sql uq_proposal_freelancer_job · Functionality | POST hai lần với cùng cặp (23001,4): 302 rồi 500, một proposal được lưu. Route chỉ finally để đóng kết nối, nên lỗi MySQL 1062 đi lên Flask. | Bắt lỗi tương ứng, hiển thị trùng proposal, giữ mã lỗi HTTP phù hợp, kiểm tra thêm form thiếu hoặc ID demo không hợp lệ. Verified; cần đồng ý trước khi sửa. |
| D-06 · MEDIUM | app/db.py dòng 15–49; sql/07_security.sql dòng 14, SETUP_LOCAL_DEMO.sql, main.py dòng 27 và các route payment/report · Functionality/SQL | MySQL routine tách quyền và suite RBAC đạt. HTTP dùng actor nhập sẵn hoặc cố định, credentials mẫu trong source, đọc bằng DB_USER mặc định root, report công khai trong demo và chưa có phiên đăng nhập người dùng. Chú thích “no passwords in repository” sai ở cấp repo. | Ghi rõ phạm vi demo localhost và tài khoản thật dùng cho phép đọc. Chỉ triển khai auth, secret quản lý ngoài mã và view/role phù hợp nếu rubric yêu cầu hệ thống nhiều người dùng. Verified về cấu hình; cần đồng ý trước khi sửa. |
| D-07 · MEDIUM | evidence/install_database_results.json, docs/test_report.md, tutorial.md dòng 5, Word §4.2 và §5, evidence/verification_summary.json · SQL/Normalization | JSON bản cài ghi SHA bắt đầu 8951131d, bundle hiện là dffe0a28. Dữ liệu chạy mới khớp 8.223, Q-05 143; số 43 là fixture lịch sử. JSON hồi quy dưới evidence của gói ghi 8.0.42, còn bộ 26.7.0 nằm trong audit_test_results. Tutorial chỉ dẫn 84/84. Rủi ro viện dẫn nhầm lần chạy. | Gắn mỗi ảnh/chỉ số với phiên bản, fixture và hash chính xác. Verifier hiện ghi đè đường dẫn JSON cố định và tự nó không xuất hash/ngày; nếu tạo bằng chứng mới nên lưu thư mục theo lần chạy. Verified; cần đồng ý trước khi sửa. |
| D-08 · LOW | sql/06_queries.sql Q-12; docs/query_report.md dòng 690–715; tests/run_tests.py Q-12 · SQL | Query runnable đếm việc trước CURRENT_DATE + 30 ngày, alias overdue_work dễ đọc là đã quá hạn. Runner khóa mốc tham chiếu; catalog/báo cáo và ví dụ cố định cần nêu ngày. 125 dòng trên fixture mở rộng ngày 15/11. | Chốt tên/chú thích và dạng tham số as-of cho demo tái lập; ca ranh giới < và ngày NULL. Verified; cần đồng ý trước khi đổi. |
| D-09 · MEDIUM | Word §1.3–1.4; main.py và templates · System Functionality | FR-01 đăng ký và FR-02 sửa hồ sơ/kỹ năng có mô hình dữ liệu, seed hoặc SQL DBA, thiếu route tương ứng. Contract hoàn tất/hủy và đổi trạng thái retry PENDING không có API người dùng. NFR-04 TLS/mã hóa và NFR-05 RPO/RTO hiện là mục tiêu. | Xác nhận yêu cầu UI tối thiểu với rubric và ghi phạm vi đã triển khai. Nếu phải mở rộng route, thêm kiểm thử theo vai trò. Verified về phạm vi source; triển khai bảo mật/restore Not Verified; cần đồng ý. |
| D-10 · LOW | Workflow_Thuyet_trinh_va_Bao_ve_SQL_G3.docx §12 · Defense/Consistency | Dẫn G3_Report_Clean.docx, tên này không có trong cây hiện tại. Đoạn “test mới” chưa theo lượt 104 mới. | Sửa tham chiếu và gắn đúng dữ liệu/phiên bản trong tài liệu luyện. Verified; cần đồng ý trước khi sửa. |

Phân loại áp dụng theo tác động trong phạm vi demo và rubric. Ca D-02 cần ưu tiên vì có thể gây sai báo cáo doanh thu/công nợ khi điều khoản bị đổi. Ca D-03 là quan sát runtime chắc chắn, quyết định đổi quy tắc vẫn phụ thuộc cách nhóm định nghĩa vòng đời job.

## E. Business Rule Coverage Matrix

Nguồn yêu cầu hiện có là Word §1.2–1.4 và Appendix A, đối chiếu docs/business_rule_matrix.md, business_rules.json và SQL. Khi nguồn mâu thuẫn, D-04 ghi cả lời mô tả tài liệu và hành vi vật lý. Rubric giảng viên dùng nguyên trọng số trong yêu cầu. W chỉ các bước Flask được gọi ở lượt này. TC/TP/CC là ID ca trong tests/run_tests.py.

| Quy tắc | Entity/quan hệ → bảng | Cơ chế thực thi | Xác minh |
|---|---|---|---|
| BR-01 User có định danh duy nhất | USER → users | PK user_id, UQ email | Verified · DDL, TC-04 kiểm email, count PK |
| BR-02 Total, disjoint và đúng loại | USER→CLIENT/FREELANCER → users, clients, freelancers | FK/PK dùng chung, discriminator, AFTER INSERT và trigger type/identity/retain | Verified · TC-01,23,24,41,42,48,49 và invariant subtype |
| BR-03 Client đăng job | CLIENT→JOB → jobs.client_id | NOT NULL FK, owner immutable, sp_post_job | Verified · TC-30, SEC-16, W |
| BR-04 Job thuộc category | JOB_CATEGORY→JOB → jobs.category_id | NOT NULL FK | Verified · TC-05 |
| BR-05 M:N kỹ năng | FREELANCER↔SKILL → freelancer_skills | Hai FK, PK ghép, CHECK skill_level | Verified · seed, Q-09 |
| BR-06 Job nhận nhiều proposal | JOB→PROPOSAL → proposals.job_id | NOT NULL FK, initial OPEN/PENDING | Verified · TC-45, Q-01 |
| BR-07 Freelancer gửi nhiều proposal | FREELANCER→PROPOSAL → proposals.freelancer_id | NOT NULL FK, native actor | Verified · Q-02, SEC-17, W |
| BR-08 Một proposal/cặp | PROPOSAL → proposals | UQ(job_id, freelancer_id) | Verified · TC-02, HTTP duplicate DB vẫn đúng |
| BR-09 Proposal có đúng job và freelancer | PROPOSAL → proposals | Hai FK và identity immutable | Verified · TC-36, cột bắt buộc |
| BR-10 Tối đa một proposal được chọn | JOB→PROPOSAL → proposals | selected_job_id, UQ nullable, job lock | Verified · TC-11 và CC-04 |
| BR-11 Hai bên xác nhận, đúng một contract | PROPOSAL→CONTRACT → contracts & proposals | UQ NOT NULL proposal_id, trigger validate/create/retain, procedure theo actor | Verified · TC-07,09,14,44; W kiểm đếm 0 trước confirm |
| BR-12 Bên mua/bán đúng nguồn | CONTRACT→CLIENT/FREELANCER → contracts | Hai FK, validate lúc INSERT, khóa identity lúc UPDATE | Verified cho parties · TC-12,13,46; giá trị thỏa thuận có lỗ hổng D-02 |
| BR-13 Milestone thuộc một contract | CONTRACT→MILESTONE → milestones | NOT NULL FK, giữ parent | Verified · TC-37, W |
| BR-14 Số tiền dương, tổng milestone ≤ hợp đồng | CONTRACT/MILESTONE | CHECK, trigger khóa contract, aggregate, READ COMMITTED | Verified · TC-03,08,21,32,47, CC-01/02/05 |
| BR-15 Hoàn thành và được duyệt trước thanh toán | MILESTONE→PAYMENT | State transition, actor, APPROVED + ACTIVE khi ghi | Verified · TC-15,25,28, SEC-09/10, W |
| BR-16 Payment là attempt, tối đa một PAID | MILESTONE→PAYMENT; dẫn xuất parties/amount | FK + CHECK method/status, generated UQ, JOIN qua contract | Verified · TC-16–20, CC-03, W; mâu thuẫn tài liệu D-04 |

FR-03–FR-10 có bằng chứng runtime cho luồng chính. FR-01–FR-02 đã triển khai ở lớp dữ liệu, bao phủ UI một phần theo D-09. Ngoài 16 BR, Word nêu các điều kiện nghiệp vụ về ngày, giữ lịch sử, trạng thái terminal, phạm vi tiền tệ và đặt lại job. Date CHECK/trigger có TC-31/33/34/35, giữ lịch sử có TC-24/29/42/43/44, giới hạn terminal có TC-27/38/40 cùng ca thất bại D-02. Một đơn vị tiền demo dùng USD theo docs; DDL dùng DECIMAL và không mang trường currency. NFR-01 đã xác minh một phần vì D-02; NFR-02 đã kiểm DB RBAC và có giới hạn HTTP D-06; NFR-03 xem benchmark mục G; NFR-04/05 chưa chạy; NFR-06 snake_case và SQL modular xác minh tĩnh.

## F. Database Normalization Audit

Ánh xạ kiểu Elmasri–Navathe áp dụng tại đây: thực thể độc lập thành bảng với khóa của nó; 1:N đặt FK bắt buộc phía N; quan hệ PROPOSAL→CONTRACT dùng FK UNIQUE NOT NULL phía CONTRACT cho 0..1 ở phía proposal và đúng một proposal ở phía contract. M:N skill có bảng kết hợp với hai FK làm PK. Specialization dùng bảng supertype và hai bảng subtype khóa chung. Hai cạnh độc lập chưa đủ diễn đạt total/disjoint nên cần discriminator và trigger.

FREELANCER_SKILL phụ thuộc khóa hai chủ thể và phù hợp mô hình quan hệ liên kết. CLIENT/FREELANCER là subtype phụ thuộc định danh từ USER. MILESTONE/PAYMENT phụ thuộc tồn tại qua FK và có PK riêng, nên tự thân tính phụ thuộc tồn tại không buộc ánh xạ weak entity kiểu khóa bộ phận. N-ary riêng, composite/multivalued attribute cần tách bảng riêng và weak entity theo partial key không xuất hiện trong schema hiện tại. Khoản thanh toán và hai vai trò là thuộc tính dẫn xuất qua các bảng đầu mối.

| Quan hệ | Khóa ứng viên / thuộc tính prime | FD phi tầm thường đại diện | Kết luận logic |
|---|---|---|---|
| users | user_id, email | mỗi khóa → full_name, hash, phone, type và khóa còn lại | BCNF |
| clients | client_id | client_id → company_name, company_description, location | BCNF |
| freelancers | freelancer_id | freelancer_id → professional_title, bio, hourly_rate, experience_level | BCNF |
| skills | skill_id, skill_name | skill_id ↔ skill_name | BCNF |
| freelancer_skills | freelancer_id + skill_id | cả cặp → skill_level | BCNF |
| job_categories | category_id, category_name | mỗi khóa → khóa còn lại, description | BCNF |
| jobs | job_id | job_id → client, category, title, mô tả, ngân sách, hạn, trạng thái, created_at | BCNF |
| proposals | proposal_id; job_id + freelancer_id | mỗi khóa → terms, status, submitted_at và khóa còn lại | BCNF logic |
| contracts | contract_id, proposal_id | mỗi khóa → parties, ngày, total_amount, status và khóa còn lại | BCNF logic, xem bất biến liên bảng D-02 |
| milestones | milestone_id | milestone_id → contract_id, title, mô tả, amount, due_date, status | BCNF |
| payments | payment_id | payment_id → milestone_id, payment_method, payment_status | BCNF logic |

Mỗi cột nghiệp vụ có giá trị nguyên tử theo miền sử dụng, đạt 1NF. Với hai khóa ghép, không có căn cứ cho skill_level chỉ phụ thuộc một ID hoặc terms proposal chỉ phụ thuộc một job hay freelancer, nên đạt 2NF. Các cột ngoài khóa nêu ở từng hàng là non-prime dưới giả định email/tên danh mục/tên kỹ năng unique theo collation, và phone, company_name, title không phải khóa. Các determinant trong phủ đều là siêu khóa nên 3NF và BCNF theo FD được công bố. Các FD tính toán (job_id,status)→selected_job_id và (milestone_id,payment_status)→paid_milestone_id có determinant không phải siêu khóa khi tính cả cột vật lý, nên chứng minh giới hạn ở phép chiếu nghiệp vụ.

PAYMENT cũ lặp amount/payer/payee ở các attempt của cùng milestone, có nguy cơ update anomaly. PAYMENT mới còn facts của attempt. Đường JOIN payments→milestones→contracts giữ đúng một kết quả trên từng payment vì FK bắt buộc và PK cha duy nhất. Phụ thuộc milestone→amount và contract→parties được giữ ở các bảng nguồn; milestone→party được tái tạo qua hai FK. Kiểm tra này chứng minh tính tái dựng các cột cũ cho mỗi attempt hợp lệ dưới bất biến cũ, không giả định rằng mọi phân rã BCNF đều bảo toàn mọi FD. Khoản tiền/parties không cần nhập lại mỗi lần retry. Diễn giải vấn đề D-02 thuộc nhất quán liên bảng và sự kiện đổi điều khoản, không tự suy ra vi phạm 3NF nội bộ CONTRACT.

## G. SQL Technical Audit

| Nhóm | Kết quả kiểm tra |
|---|---|
| 01_schema | 11 bảng InnoDB. ID INT có dư địa cho fixture; tiền DECIMAL(15,2), hourly_rate DECIMAL(10,2), ngày nghiệp vụ DATE, timestamp tạo/gửi dùng DATETIME. VARCHAR cho email, tên, trạng thái có CHECK hoặc UQ tương ứng, mô tả TEXT. Hạn/date, NULL bắt buộc, lỗi FK, tiền và trạng thái có kiểm SQL. Không đo mọi giá trị cực biên của VARCHAR/DECIMAL, timezone hoặc chuẩn hóa Unicode trên DBMS khác. |
| 02_triggers | 21 trigger. tr_users_create_subtype, tr_users_identity_immutable; clients/freelancers mỗi nhóm type, identity, retain; tr_jobs_owner; proposals initial/transition/create_contract; contracts validate/update/retain; milestones insert/update/delete; payments insert/update/delete. Hai generated UNIQUE chặn cạnh tranh; kiểm tra 5 ca đồng thời có xác nhận trạng thái cuối. Seed thực thi nhiều câu INSERT/UPDATE đa dòng và chuỗi trigger. Ca direct DBA D-02/D-03 nằm ngoài hồi quy hiện có. |
| 03_views_indexes | v_job_proposals, v_contract_overview, v_client_spend. View hợp đồng tổng hợp milestone và paid riêng, tránh nhân bản với nhiều retries. Hai index thêm là ix_jobs_status_budget và ix_milestones_status_due. InnoDB tạo index FK khi cần. UQ proposal ghép bắt đầu bằng job_id, UQ proposal_id của CONTRACT hỗ trợ FK tương ứng; SHOW INDEX xác nhận CONTRACT và PAYMENT. |
| 04_procedures | 7 procedure, SQL SECURITY DEFINER. Select/confirm/advance/add/payment dùng transaction sở hữu riêng, handler rollback và khóa parent. Post/submit dùng INSERT và commit phía caller. Role có EXECUTE theo scope. Có phụ thuộc cấu hình definer và bootstrap. Test local tạo từ root, docs đề xuất definer đặc quyền tối thiểu khi triển khai. |
| 05,08,09 | Fixture base 8 jobs và fixture mở rộng 1.008 jobs được kiểm riêng. Bản 08 có 500 VALUES tại dải 21201–21700. Các section bundle khớp SQL modular theo nội dung, khác một dòng trống giữa VALUES và UPDATE trong section 08 của installer. SAMPLE_DATA khớp 05/08. Dùng trên schema mới. |
| 06_queries | Q01 left join/count, Q02 HAVING, Q03 NOT EXISTS, Q04 CTE+DENSE_RANK, Q05 view client spend, Q06 outstanding, Q07 anti-payment, Q08 scalar AVG, Q09 JOIN+HAVING, Q10 view contract, Q11 top đồng hạng, Q12 range + aggregate. Base xác minh 12 kết quả. Scale xác minh thực thi và thu row count. Q06 lọc outstanding, có thể gồm CANCELLED nếu câu hỏi là số chênh số học; cần thống nhất nếu diễn giải là phải thu. |
| 07_security | 4 roles, 10 accounts khởi tạo khóa khi cài mới; GRANT/REVOKE và DEFAULT ROLE. SETUP_LOCAL_DEMO mở 3 account khi chạy riêng. Test RBAC gồm quyền table, procedure, actor ownership và analyst views. |

**Chạy mới trên MySQL 26.7.0**

| Lượt kiểm | Kết quả |
|---|---|
| Native mysql chạy INSTALL_DATABASE.sql | Exit 0; 11 bảng, 3 views, 21 triggers, 7 procedures; 8.223 dòng. |
| 01→02→03→04→05→08→07→09→06 trong một session | Exit 0; đúng count, chạy SELECT; verifier đạt. |
| 01→02→03→04 và SAMPLE_DATA.sql | Exit 0; đúng count, verifier đạt. Đường này cung cấp schema, routines và dữ liệu; role setup là bước riêng. |
| tests/run_tests.py --install --security | Exit 0; 72/72 + 12/12 + 20/20. Dùng bản sao tạm; runner tái tạo schema giữa kiểm thử toàn vẹn và truy vấn. |
| tests/verify_large_dataset.py | 9 invariant không vi phạm; 12 SELECT có số dòng lần lượt 1008, 204, 101, 204, 143, 485, 483, 494, 202, 605, 40, 125. Q12 phụ thuộc ngày MySQL 15/11/2026. |
| Kiểm thử bổ sung | D-02/D-03 tái hiện bằng ca SQL sau khi tạo/chi trả contract mới; D-05 tái hiện từ Flask. |

| Bảng trên fixture mở rộng | Dòng | Bảng | Dòng |
|---|---:|---|---:|
| users | 748 | clients | 143 |
| freelancers | 605 | skills | 26 |
| freelancer_skills | 610 | job_categories | 11 |
| jobs | 1.008 | proposals | 1.811 |
| contracts | 605 | milestones | 1.810 |
| payments | 846 | **Tổng** | **8.223** |

EXPLAIN Q08 dùng PRIMARY scan ở query ngoài do ORDER BY job_id; AVG chạy một lần, quét covering ix_jobs_status_budget. Q12 dùng range scan ix_milestones_status_due với điều kiện trạng thái/hạn, lookup PK contract và bảng tạm khi aggregate. Các route chính dùng truy vấn set-based hoặc vài SELECT cố định, chưa thấy vòng lặp Python truy vấn theo từng dòng. Hai index thêm làm tăng chi phí ghi và lưu trữ; không có cơ sở thêm index FK lặp. Cân nhắc (milestone_id,payment_status) chỉ sau khi đo trên workload truy vấn retry lớn. Benchmark tái chạy trên 5.000 jobs và 10.000 proposals với 1 lần làm nóng, 30 lượt đo mỗi phương án. Median **0,198 ms** khi optimizer dùng index, **1,340 ms** khi IGNORE INDEX, kết quả 20 dòng giống nhau. EXPLAIN ANALYZE cho thấy covering range scan ngược so với table scan + sort. Kết quả áp dụng cho truy vấn lọc OPEN/budget của benchmark.

## H. Integration & Live Demo Audit

| Hạng mục | Trạng thái và bằng chứng |
|---|---|
| Home, Client, Freelancer, danh sách proposal/hợp đồng/milestone và Reports | Verified · Flask test client qua Jinja và MySQL thật, các GET trả 200. |
| Đăng job, gửi và chọn proposal | Verified · POST trả 302 và giá trị đọc lại từ DB; lúc CLIENT_ACCEPTED có 0 contract cho proposal. |
| Freelancer xác nhận, Client thêm milestone | Verified · Contract và milestone xuất hiện trong MySQL. |
| Bắt đầu, hoàn thành, Client duyệt | Verified · IN_PROGRESS → COMPLETED → APPROVED; khi chưa APPROVED payment bị chặn, 0 dòng. |
| Ghi FAILED rồi PAID, thử PAID lần hai | Verified · Chỉ FAILED, PAID được lưu; view paid 500, outstanding 0 trước thử thay đổi D-02. |
| Gửi trùng proposal | Failed · Web trả 500, DB vẫn giữ một dòng. |
| Khởi động Workbench và duyệt trình duyệt trực tiếp, Compose, máy khác | Not Verified · Run dùng native mysql và Flask test client, dependencies trên máy này có sẵn. Docker CLI không thấy trên PATH. |
| Đăng ký/sửa hồ sơ và kỹ năng qua UI | Not Applicable đối với demo giao dịch chính; thiếu nếu rubric yêu cầu mọi FR phải có giao diện. |
| TLS, backup/restore, gateway, escrow, ví và rating | TLS/backup Not Verified theo NFR; gateway/escrow và rating ngoài phạm vi hiện tại. |

**Kịch bản trình bày**. Dùng instance riêng với installer sạch, chạy SETUP_LOCAL_DEMO.sql, cấu hình DB_HOST/DB_PORT/DB_USER/DB_PASSWORD theo đúng instance và chạy python main.py từ thư mục gói. Mở trang Home xác nhận mini_upwork, mở Client/Freelancer. Client 1 đăng job ngân sách 100–200 với tên riêng, Freelancer 4 đề xuất 150. Client chọn, dùng SELECT proposals và contracts để chứng minh chưa có contract. Freelancer xác nhận, Client thêm milestone 150. Chuyển trạng thái qua IN_PROGRESS và COMPLETED. Để minh họa lỗi có xử lý, dùng payment trước APPROVED trên bản tạm hoặc ca DB vượt ngân sách; kiểm DB giữ nguyên. Duyệt, ghi FAILED rồi PAID, tải lại Reports và so sánh đúng contract_id trong v_contract_overview. Chứng minh quyền bằng report_reader được DBA setup trong phiên riêng với một SELECT view thành công và SELECT hash bị từ chối. Chụp lại ID từ màn hình, tránh nhầm dữ liệu seed. Diễn tập trước bằng trình duyệt/Workbench trên chính máy sẽ chiếu.

## I. Individual Defense Preparation

Mỗi thành viên luyện cả ba mức. Các SQL dưới đây là ví dụ MySQL 26.7.0 đọc dữ liệu, hoặc CALL minh họa nên dùng trong schema diễn tập với account đúng. Chúng bổ sung tài liệu workflow, không phải biên bản từng sinh viên trả lời.

| # · Mức | Câu hỏi và kiến thức | Hướng giải / SQL mẫu | Lỗi dễ mắc |
|---|---|---|---|
| 1 · Cơ bản | Hai loại user có bao nhiêu dòng? GROUP BY | SELECT user_type, COUNT(*) FROM users GROUP BY user_type; | Đếm subtype lẫn với tổng users. |
| 2 · Cơ bản | Ai đăng job? Quan hệ USER→CLIENT→JOB | SELECT j.job_id,u.full_name FROM jobs j JOIN users u ON u.user_id=j.client_id; | Nối bằng tên thay vì khóa. |
| 3 · Cơ bản | So sánh PK và candidate key của proposal. UNIQUE ghép | SHOW INDEX FROM proposals; giải thích PK proposal_id và UQ(job_id,freelancer_id). | Nhầm từng cột trong cặp là UNIQUE. |
| 4 · Cơ bản | Vì sao DECIMAL cho tiền và cột nào có thể NULL? | SHOW COLUMNS FROM milestones; SELECT amount,due_date FROM milestones WHERE due_date IS NULL; | Dùng = NULL hoặc FLOAT. |
| 5 · Cơ bản | Mốc nào có nhiều payment attempts? FK 1:N | SELECT milestone_id,COUNT(*) FROM payments GROUP BY milestone_id HAVING COUNT(*)>1; | Hiểu mọi attempt đều PAID. |
| 6 · Trung bình | Đếm proposal gồm job không có đề xuất. LEFT JOIN | SELECT j.job_id,COUNT(p.proposal_id) FROM jobs j LEFT JOIN proposals p ON p.job_id=j.job_id GROUP BY j.job_id; | COUNT(*) trả 1 cho dòng cha không con. |
| 7 · Trung bình | Tìm freelancer có ít nhất 3 skill. PK ghép và HAVING | SELECT freelancer_id,COUNT(*) FROM freelancer_skills GROUP BY freelancer_id HAVING COUNT(*)>=3; | Dùng WHERE với biểu thức COUNT. |
| 8 · Trung bình | Tìm job chưa nhận proposal. Anti-join | SELECT j.job_id FROM jobs j WHERE NOT EXISTS (SELECT 1 FROM proposals p WHERE p.job_id=j.job_id); | Quên correlation. |
| 9 · Trung bình | Tổng tiền PAID từng freelancer. JOIN và aggregate | SELECT c.freelancer_id,SUM(m.amount) FROM payments p JOIN milestones m ON m.milestone_id=p.milestone_id JOIN contracts c ON c.contract_id=m.contract_id WHERE p.payment_status='PAID' GROUP BY c.freelancer_id; | Cộng FAILED hoặc dùng p.amount cũ. |
| 10 · Trung bình | Mở bảng contract: vì sao proposal_id là khóa? Ánh xạ 0..1 | SHOW CREATE TABLE contracts; chỉ ra UNIQUE và NOT NULL, trigger bảo đảm hướng xác nhận. | FK đơn thuần chỉ diễn đạt N:1. |
| 11 · Nâng cao | Top client giữ đồng hạng. Window function | WITH n AS (SELECT client_id,COUNT(*) k FROM jobs GROUP BY client_id), r AS (SELECT n.*,DENSE_RANK() OVER(ORDER BY k DESC) pos FROM n) SELECT client_id,k FROM r WHERE pos=1; | LIMIT 1 bỏ đồng hạng. |
| 12 · Nâng cao | Điều chỉnh Q12 chỉ đếm đã quá hạn. Ranh giới ngày | SELECT contract_id,COUNT(*) FROM milestones WHERE status IN ('PENDING','IN_PROGRESS','COMPLETED') AND due_date<CURRENT_DATE AND EXISTS (SELECT 1 FROM contracts c WHERE c.contract_id=milestones.contract_id AND c.status='ACTIVE') GROUP BY contract_id; | Gọi “quá hạn” cho cửa sổ 30 ngày tới hoặc đưa APPROVED vào. |
| 13 · Nâng cao | MySQL dùng index nào cho jobs OPEN? | EXPLAIN SELECT job_id,budget_max FROM jobs WHERE status='OPEN' AND budget_max>=4800 ORDER BY budget_max DESC LIMIT 20; đối chiếu với IGNORE INDEX (ix_jobs_status_budget). | So thời gian một lần hoặc bỏ qua độ chọn lọc. |
| 14 · Nâng cao | Hai giao dịch cùng chi ngân sách vượt contract. Khóa và isolation | SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED; START TRANSACTION; SELECT total_amount FROM contracts WHERE contract_id=1 FOR UPDATE; ROLLBACK; giải thích khóa parent và xem CC-01/02. | Chỉ dùng CHECK từng dòng hoặc quên kết thúc transaction. |
| 15 · Nâng cao | Vì sao không thể ghi hai PAID? Generated column và NULL | SHOW CREATE TABLE payments; SELECT milestone_id,SUM(payment_status='PAID') FROM payments GROUP BY milestone_id HAVING SUM(payment_status='PAID')>1; giải thích UNIQUE cho mỗi giá trị khác NULL. | Đặt UNIQUE trên milestone_id làm mất retry. |
| 16 · Nâng cao | Giải thích hai bước xác nhận và actor. SQL SECURITY DEFINER | SHOW CREATE PROCEDURE sp_confirm_proposal; CALL sp_confirm_proposal(4,24801); ví dụ CALL chỉ hợp lệ khi ID là proposal vừa chọn trên bản diễn tập và dùng account freelancer_4. | Gọi bằng root hoặc gộp vào transaction của caller. |

| Thành viên | Dấu vết quan sát được | Phần luyện chính, cả ba vẫn phải tự viết các truy vấn |
|---|---|---|
| Huỳnh Thiện Đức | 0b87692 tạo tài liệu workflow; e86fcbc sửa README hai cấp. | BR→EER→DDL và câu 1–5, 10; lấy một commit để trình bày quyết định đã tham gia. |
| Phạm Việt Hoàng | 483583b tạo báo cáo Word; 0204c6f cập nhật tài liệu EER ở tên file lịch sử. | FD, PAYMENT và câu 6–10,15; mô tả mapping hoặc nội dung Word mình đã thực hiện. |
| Đặng Quang Huy | 187939b thay đổi main.py; e5d9056 thêm JSON hồi quy 26.7.0. | Demo, transaction, RBAC, EXPLAIN và câu 11–16; trình bày một trace hoặc kết quả kiểm thử có thể tái lập. |

Git metadata cho thấy thay đổi trong các commit đã nêu. Phần việc ngoài Git, đồng tác giả, cách nhóm chia công việc và mức tham gia cần xác nhận trực tiếp. Đề nghị mỗi thành viên mang một commit/tài liệu, mô tả quyết định và tự sửa một query khi đổi đề, sau đó đối chiếu với nhận xét của nhóm. Individual Defense và Peer Evaluation còn TBD.

## J. Prioritized Action Plan

| Thứ tự | Việc và file | Tác động / rủi ro | Xác minh |
|---|---|---|---|
| 1 | Giải quyết conflict hai README, pin đúng hướng dẫn Compose, phân rõ test archive và demo mới. | Loại bỏ nhầm port/dataset, rủi ro tài liệu thấp. | Tìm marker, đối chiếu YAML, cài sạch bằng hướng dẫn. |
| 2 | Chốt chính sách điều khoản khi đã ký và terminal. Sửa trigger/schema nếu cần, cập nhật bundle và test. | Bảo vệ invariant số tiền. Có thể ảnh hưởng seed/DBA edits hợp lệ; cần duyệt luật và thiết kế nhất quán. | Tái hiện D-02, rollback kiểm tra, chạy lại đủ 104 và scale. |
| 3 | Quyết định liên kết JOB/CONTRACT khi hoàn tất/hủy; bổ sung đường cập nhật hoặc ghi phạm vi. | Ảnh hưởng bộ lọc, reports, seed và lock order. | Chạy ca terminal, kiểm hai trạng thái và job reserve; test concurrent. |
| 4 | Xử lý lỗi form/duplicate trong main.py/templates; diễn tập local login demo. | Giảm HTTP 500; giữ đúng SQL errno và actor. | POST duplicate, form thiếu, account khóa, payment trước duyệt; kiểm feedback và số dòng DB. |
| 5 | Cập nhật schema_metadata, Mermaid, BR JSON, Word và workflow sau khi chốt; thêm metadata hash/fixture cho verifier. | Một baseline nhất quán; cần giữ dấu vết historical. | So tên cột/PK/FK với INFORMATION_SCHEMA; kiểm Q-05/Q-12 và hash kết quả. |
| 6 | Đo thêm khi cần mở rộng dữ liệu, dượt demo và bảo vệ. | Tránh thêm index dư; sớm phát hiện vấn đề trên máy trình bày. | EXPLAIN, timed runs, trình duyệt/Workbench và từng người làm bài SQL. |

## K. Final Verdict

1. **Đáp ứng đầy đủ rubric?** Chưa. Phần lớn dữ liệu và luồng chính đã có bằng chứng; các mâu thuẫn hướng dẫn, integrity hợp đồng và UX ngoại lệ cần xử lý. Defense và Peer cần đánh giá trực tiếp.
2. **Tiêu chí đã có bằng chứng đạt?** Mô hình 11 bảng và luồng nghiệp vụ chính, ánh xạ PK/FK/subtype, chuẩn hóa logic theo FD đã nêu, cài SQL và kiểm tra hồi quy, Flask đi đến ghi nhận PAID.
3. **Chưa đạt hoặc chưa kiểm chứng?** D-01, D-02, D-04, D-05 đã tái hiện hoặc đối chiếu. D-03 cần chốt luật. Compose, máy khác, mở bằng Workbench/trình duyệt, TLS, restore và cá nhân chưa xác minh.
4. **Rủi ro khi nộp?** Marker Git và sai phiên bản dễ thấy khi chấm, metadata PAYMENT cũ làm suy yếu EER/DDL, ca terminal lệch khoản phải trả khi chạy ngoài regression, HTTP 500 làm gián đoạn demo.
5. **Trước bảo vệ?** Giải quyết tài liệu cài, chốt hai điều kiện terminal, diễn tập mục H với có ca lỗi và role, kiểm lại sơ đồ và chuẩn bị ít nhất hai truy vấn cho từng người.
6. **Live demo hiện có thể chạy?** Luồng chuẩn qua Flask đã xác minh trên MySQL tạm. Dùng fixture sạch với Client 1/Freelancer 4; xác minh trình duyệt và Workbench tại máy trình bày trước buổi chấm.
7. **Cần xác nhận thay đổi nào?** Quy tắc sửa điều khoản đã ký, đồng bộ JOB/CONTRACT, phạm vi UI/đăng nhập; sau khi xác nhận mới sửa README, Word, SQL, app/test và cập nhật bằng chứng. Báo cáo này là file mới duy nhất được tạo trong dự án.

### Vị trí tài liệu và bằng chứng

- [Bản cài](Freelance_Marketplace_Ecosystem_SQL/INSTALL_DATABASE.sql) · [Số đếm kỳ vọng](Freelance_Marketplace_Ecosystem_SQL/evidence/install_database_expected_counts.json) · [Tutorial](tutorial.md) · [Compose](Freelance_Marketplace_Ecosystem_SQL/compose.yaml).
- [Word dự án](Freelance_Marketplace_Ecosystem_G3.docx) · [Word workflow](Workflow_Thuyet_trinh_va_Bao_ve_SQL_G3.docx) · [Audit 3NF](audit_report_3NF.md).
- [Hồi quy 26.7.0 đã lưu](audit_test_results/verification_2026-11-15/verification_summary.json) · [Hồi quy 8.0.42](Freelance_Marketplace_Ecosystem_SQL/evidence/verification_summary.json) · [SHA cũ của bản cài 8.223 dòng](Freelance_Marketplace_Ecosystem_SQL/evidence/install_database_results.json). Kết quả mới nằm ở mục G/H. JSON do runner tạo trong bản sao tạm, các JSON có sẵn trong repo vẫn giữ nguyên.
