# Hướng dẫn demo và chuẩn bị bảo vệ G3

## Chuẩn bị

Đọc README, cài vào instance riêng, đặt mật khẩu cho client_1, freelancer_4 và payment_service. Chạy app ở localhost. Dùng ba browser profiles hoặc private windows cho ba role; HTTP Basic thường giữ credential đến khi đóng cửa sổ.

App không tự đăng ký native account cho mọi business user. Dùng actor 1 cho client, actor 4 cho freelancer, actor 1 cho payer khi payment_service ghi kết quả. Các mã ID phải lấy từ lần chạy thực tế, không dùng lại một mã đã hoàn tất rồi mong seed tự reset.

## Luồng trình diễn

1. Client 1: form Post Job; actor=1, category=1, title tùy chọn, description đầy đủ, min/max budget=100. Không cần deadline.
2. Xem job ID mới nhất trên v_job_proposals. Freelancer 4: Submit Proposal, actor=4, job=<ID>, amount=100, letter tùy chọn, days=30.
3. Lấy proposal ID bằng SQL bên dưới. Client 1: Select Proposal. Cho thấy chưa có contract trước freelancer confirmation.
4. Freelancer 4: Confirm Proposal. Client xem v_contract_overview lấy contract ID.
5. Client 1: Add Milestone, amount=100, title tùy chọn, due bỏ trống. Lấy milestone ID bằng SQL.
6. Freelancer 4: Advance Milestone lần lượt IN_PROGRESS rồi COMPLETED.
7. Client 1: Advance Milestone thành APPROVED. Trước bước này có thể thử payment để trình bày lỗi bị chặn.
8. Payment service: Record Payment, actor=1, method=PAYPAL, status=FAILED, rồi PAID. Lần PAID thứ hai bị unique index từ chối.
9. Client 1: Complete Contract; sau đó Submit Review, rating=5. Review trước completion, ngoài miền hoặc trùng contract bị chặn.
10. Xem Q13–15 để kiểm tra count/mean. Dashboard chỉ hiện 25 ID mới nhất nên một freelancer có ID nhỏ có thể cần chạy query lọc riêng.

SQL tra cứu cho DBA ở cửa sổ riêng:

```sql
USE mini_upwork;
SELECT job_id,title,status FROM jobs ORDER BY job_id DESC LIMIT 5;
SELECT proposal_id,job_id,freelancer_id,status FROM proposals ORDER BY proposal_id DESC LIMIT 5;
SELECT contract_id,proposal_id,status,total_amount FROM contracts ORDER BY contract_id DESC LIMIT 5;
SELECT milestone_id,contract_id,status,amount FROM milestones ORDER BY milestone_id DESC LIMIT 5;
SELECT * FROM v_payment_details ORDER BY payment_id DESC LIMIT 5;
SELECT * FROM v_freelancer_ratings WHERE freelancer_id=4;
```

Đây là thao tác DBA hỗ trợ demo, không phải quyền SELECT base table cấp cho actor. Không đưa root credential vào ứng dụng.

## Câu hỏi luyện tập

1. Vì sao proposal có hai candidate keys? Chứng minh (job_id, freelancer_id) là minimal key.
2. Hai liên kết user–subtype 0..1 có đủ diễn đạt total/disjoint không? Trigger nào bổ sung invariant đó?
3. Tại sao một FK không bảo đảm tổng milestone không vượt giá trị contract?
4. Hai session cùng thêm 60 vào contract 100: khóa hàng nào, vì sao không cùng được ghi?
5. CLIENT_ACCEPTED khác CONFIRMED như thế nào? Lúc nào contract được tạo?
6. Vì sao payments cũ vi phạm 3NF khi cho retry? Bản mới phục hồi payer/payee/amount qua JOIN ra sao?
7. Tại sao chỉ cộng PAID? JOIN trực tiếp review × milestone × payment có thể làm sai số liệu như thế nào?
8. Functional unique index xử lý các dòng không PAID và NULL như thế nào?
9. Candidate key của contract_reviews là gì? Vì sao không cần lưu reviewer_id và recipient_id?
10. Với freelancer chưa có review, tại sao count=0 và mean=NULL thay vì mean=0?
11. USER() khác CURRENT_USER() trong SQL SECURITY DEFINER như thế nào?
12. Vì sao không gọi procedure có START TRANSACTION trong transaction do caller đã mở?
13. Sửa Q12 thành công việc đến hạn trong 30 ngày tới: cần cả cận dưới và cận trên nào?
14. Viết query top freelancer có ít nhất 3 reviews, rồi giải thích HAVING, AVG và cách xử lý đồng hạng.
15. Kết quả đo query local khác SLA production thế nào? Chỉ mục thêm có chi phí gì?

## Mẫu nhóm tự xác nhận

Phân chia chủ đề tập luyện có thể là accounts/normalization; workflow/concurrency; queries/app. Đây là gợi ý, không phải lịch sử đóng góp.

| Thành viên | Công việc thực sự đã thực hiện | File/commit/bằng chứng | Phần tự trình bày |
|---|---|---|---|
| Huynh Thien Duc | Nhóm tự điền | Nhóm tự điền | Nhóm tự xác nhận |
| Pham Viet Hoang | Nhóm tự điền | Nhóm tự điền | Nhóm tự xác nhận |
| Dang Quang Huy | Nhóm tự điền | Nhóm tự điền | Nhóm tự xác nhận |

Peer evaluation dùng đúng biểu mẫu/thang điểm thầy cung cấp nếu có. Ghi nhận xét và điểm sau khi cả nhóm rà công việc; tài liệu này không tự cho điểm. Live presentation và SQL defense vẫn phải được các thành viên thực hiện.
