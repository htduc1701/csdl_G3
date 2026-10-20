# Nhật ký thay đổi so với bài cũ

| Hạng mục | Giữ lại | Sửa hoặc bổ sung | Lý do |
|---|---|---|---|
| Bài báo cáo | Danh tính nhóm, domain, BR-01…15, nền tảng mô hình và dữ liệu | Viết bản Word mới, bổ sung các phần thiếu, không ghi đè bản cũ | Có sản phẩm riêng để nộp và đối chiếu |
| Accounts/skills/jobs | Các bảng, shared subtype keys và quan hệ chính | Vẽ lại model thống nhất và dictionary từ metadata | Tránh lệch báo cáo với triển khai |
| Proposal/contract | Mutual consent, trigger tạo contract, key thay thế | Functional unique indexes; cố định total_amount/start_date; đồng bộ trạng thái job khi contract kết thúc | Loại helper columns khỏi schema logic, giữ điều khoản và trạng thái nhất quán |
| Payment | Retry, approval, một PAID, audit retention | Bỏ amount/payer/payee trong payments, thêm v_payment_details; sửa seed/procedure/views | Khắc phục non-key FD vi phạm 3NF trong thiết kế cũ |
| Rating | Không có trước đó | contract_reviews, completion/immutability triggers, authenticated procedure, AVG/COUNT, seed, test | Đáp ứng user-rating aggregation trong ảnh đề |
| Dữ liệu | 7223 bản ghi giả lập của 11 bảng | Thêm 120 reviews; hoàn tất các contract đủ điều kiện qua guards | 7343 dòng trên 12 bảng sau fresh install |
| SQL/query | Kế thừa 12 truy vấn nghiệp vụ | Q12 đổi thành strictly overdue; Q13–15 rating; module/install/data cùng nguồn | Đúng nghĩa chỉ số và không thiếu rating |
| Kiểm thử | Tham khảo ý tưởng và invariant trong runner cũ | Runner mới phù hợp schema; 59 assertions, trong đó 10 dataset invariants; 15 query có output/plan/timing | Không tái sử dụng PASS cũ hoặc chạy script DROP trên DB nhóm |
| Giao diện | Bài cũ chưa có mã ứng dụng | Python local HTTP demo dùng native account và procedure; token form và escaped output | Thực hiện phần integration được yêu cầu |
| README | Thông tin nhóm và hướng dẫn hợp lệ | Bản mới không conflict, tên SAMPLE_DATA đúng, cài đặt rõ | Giảm lỗi khi tái lập và bảo vệ |
| Evidence | Bằng chứng lịch sử nằm nguyên ở folder gốc | evidence mới tách biệt và ghi engine 26.7.0 | Trung thực nguồn và phạm vi kết quả |

## Điều chỉnh trong quá trình kiểm thử

- Seed review bằng INSERT SELECT đụng quy tắc MySQL 1442 khi trigger khóa lại parent đang được câu lệnh đọc. Đã đổi sang cursor và INSERT VALUES; vẫn chạy trigger, không tắt ràng buộc.
- Runner ban đầu bọc CALL trong transaction nên nhận 1568 thay vì kiểm tra nghiệp vụ. Đã sửa test để gọi procedure theo giao ước standalone transaction.
- Dashboard ban đầu giới hạn 25 ID đầu, không hiện job vừa tạo. Đã chuyển thành 25 ID mới nhất.
- Kết quả bàn giao là lần chạy cuối đạt 59/59; các lần lỗi dùng để sửa không được gộp vào số PASS.

## Kiểm chứng và giới hạn

Chỉ fresh install được kiểm chứng, chưa cung cấp migration in-place cho DB cũ. Việc giữ mã nguồn gốc cho phép nhóm so sánh; không chạy script mới chồng lên schema cũ. Bản báo cáo không nhận 104 PASS cũ, không nhận kiểm thử trên MySQL 8.0, không tự khai completed presentation hoặc peer evaluation.

Metadata và hash gốc ghi ở evidence. Phần kiểm tra bố cục/xuất PDF được ghi riêng trong `evidence/document_qa.json` khi hoàn tất.
