# Đối chiếu yêu cầu của thầy

Nguồn A: Industrial Documentation Standards and Frameworks, 2 trang. Nguồn B: Milestone Project Plan and Evaluation, 2 trang. Nguồn C: ảnh đề Project 3. Các nguồn được giữ ở `../tai_lieu_goc/`. Đây là bảng rà soát nội bộ, không thay cho báo cáo nộp.

| ID | Yêu cầu và nguồn | Sản phẩm đáp ứng | Trạng thái và giới hạn |
|---|---|---|---|
| A1 | User requirements riêng system capabilities, FR/NFR, BR; A trang 1 | Báo cáo §1, mã UR/FR/NFR/BR | Đã viết lại và truy vết; NFR chưa đo được ghi rõ |
| A2 | IE Crow’s Foot hoặc UML; mapping appendix nếu dùng Elmasri; A trang 1 | Báo cáo §2, diagrams/01–04 .dot/.svg/.png | Dùng UML-style class compartments và multiplicities, không dùng Elmasri |
| A3 | Dictionary mọi bảng có attribute/type/key/null/default/rules; A trang 1–2 | Báo cáo §4, database/Data_Dictionary.md | 12 bảng; lấy kiểu/khóa/default từ metadata schema đã chạy |
| A4 | snake_case, keyword uppercase, indent; A trang 2 | database/sql/, INSTALL_DATABASE.sql | Giữ một dialect; module và script tổng hợp đồng bộ |
| B1 | Problem statement, BR và ER/EER; B trang 1, Phase 1 20% | Báo cáo §1–2, Appendix A | Bao phủ scenario và 18 BR; BR cụ thể là thiết kế nhóm |
| B2 | Relational mapping, FK và 3NF/BCNF proof; B trang 1, Phase 2 20% | Báo cáo §2–4 | Candidate key/FD từng quan hệ; sửa payments, giải thích reconstruction lossless |
| B3 | DDL, DML, 10+ complex queries, 2 Triggers/Views; B trang 1, Phase 3 30% | database/, báo cáo §5–7 | Cài mới thành công; 15 query, 5 view, nhiều trigger; không đổi cách diễn đạt quota trong nguồn |
| B4 | UI/backend đơn giản nối database; B trang 1–2 | app/server.py, báo cáo §8 | HTTP đọc DB và tạo job đã chạy; workflow đủ từ job đến review qua native procedure |
| B5 | Live group presentation, individual SQL defense, peer evaluation; B trang 1–2, Phase 4 30% | Huong_dan_demo_va_bao_ve.md | Có tài liệu luyện tập; nhóm phải tự thực hiện và xác nhận |
| B6 | Nhóm ba người, không một người làm tất cả; B trang 1 | Trang bìa và mẫu phân công | Giữ danh tính; không bịa đóng góp hoặc điểm |
| B7 | Group rubric 70%, individual 30%; B trang 1–2 | Báo cáo §8 | Phân biệt với tỷ trọng các Phase; không tự chấm điểm |
| C1 | Client/freelancer, jobs, contract, milestone, payment releases; ảnh đề | Schema, procedure, báo cáo §1–2 và §5 | Đã cài/chạy luồng và kiểm tra trường hợp sai |
| C2 | Multi-party transactions và milestone tracking; ảnh đề | Parent locks, đồng thuận, workflow, test | Một race ngân sách hai session và 10 invariant toàn dữ liệu; không khẳng định mọi schedule |
| C3 | User-rating aggregation; ảnh đề | contract_reviews, v_freelancer_ratings, Q13–15 | Bổ sung một chiều client→freelancer sau hoàn tất; score 1–5, count+mean, no-rating NULL |

## Những điều không được gán thành yêu cầu của thầy

- 11 bảng: là thiết kế cũ; bản mới có 12 bảng.
- 1000 dòng tối thiểu: không xuất hiện trong hai PDF; giữ fixture lớn như lựa chọn của nhóm.
- Giữ payer/payee/amount lặp vật lý trong payments: là cách diễn đạt BR cũ, đã thay bằng thông tin suy ra qua view.
- 104 PASS trên 8.0.42: bằng chứng cũ, không xác nhận bản mới. Bản mới có 59 PASS trên 26.7.0.
- Production SLA, mã hóa ổ đĩa, phục hồi backup: không coi đã làm chỉ vì có viết NFR.

## Bằng chứng mới

`evidence/verification_results.json` chứa từng assertion/lỗi kỳ vọng và thực tế. `dataset_counts.json` đếm fixture trước test; `query_results.json` đo sau khi test thêm dữ liệu. `schema_metadata.json` là metadata từ server đã cài thật. Ngày giờ thực thi ghi UTC trong JSON; ngày báo cáo theo Asia/Saigon.
