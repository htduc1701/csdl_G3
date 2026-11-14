# Kiểm chứng bộ dữ liệu thực tế giả lập

Đã nạp thực tế bằng INSTALL_DATABASE.sql trên MySQL 8.0.42, isolation READ-COMMITTED. Tất cả tên người và công ty là giả lập; tiền dùng USD theo giả định của bộ demo.

## Số bản ghi

| Bảng | Số bản ghi |
|---|---:|
| users | 248 |
| clients | 43 |
| freelancers | 205 |
| skills | 26 |
| freelancer_skills | 610 |
| job_categories | 11 |
| jobs | 1008 |
| proposals | 1811 |
| contracts | 605 |
| milestones | 1810 |
| payments | 846 |
| **Tổng** | **7223** |

## Kiểm tra tính nhất quán

| Kiểm tra | Số vi phạm |
|---|---:|
| subtype_violation | 0 |
| duplicate_proposal_pair | 0 |
| multiple_selected | 0 |
| missing_confirmed_contract | 0 |
| bad_contract_parties | 0 |
| milestone_overflow | 0 |
| bad_payment | 0 |
| multiple_paid | 0 |
| milestone_dates | 0 |

## Kiểm tra nội dung dữ liệu

| Kiểm tra | Kết quả |
|---|---:|
| unique_people | 248 |
| unique_job_titles | 1008 |
| placeholder_names | 0 |
| placeholder_jobs | 0 |
| category_assignment_mismatches | 0 |

## Kết quả 12 truy vấn trên dữ liệu mới

Các bảng bên dưới hiển thị tối đa 10 dòng đầu mỗi truy vấn. Đây là bằng chứng thực thi, không phải kiểm thử đối chiếu độc lập mọi giá trị của bộ dữ liệu lớn. Bộ kiểm thử nhỏ lịch sử được giữ riêng.

### Q-01

Số dòng kết quả: 1008.

```sql
SELECT *
FROM v_job_proposals
ORDER BY job_id
```

| job_id | client_id | title | status | budget_max | proposal_count | selected_count |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | Xây dựng cổng đặt hàng cho An Nhiên Retail | IN_PROGRESS | 1000.00 | 2 | 1 |
| 2 | 1 | Thiết kế bộ giao diện đặt trà cho Mộc Trà Studio | IN_PROGRESS | 800.00 | 2 | 1 |
| 3 | 2 | Dashboard theo dõi giao hàng của Mộc Trà Studio | IN_PROGRESS | 1500.00 | 2 | 1 |
| 4 | 2 | API quản lý yêu cầu cho Mộc Trà Studio | IN_PROGRESS | 600.00 | 1 | 1 |
| 5 | 3 | Pipeline đối soát đơn vận chuyển của Hải Đăng Logistics | IN_PROGRESS | 2000.00 | 2 | 1 |
| 6 | 3 | Báo cáo chi phí tuyến giao hàng Hải Đăng Logistics | OPEN | 900.00 | 1 | 1 |
| 7 | 1 | Thiết kế trang giới thiệu bộ sưu tập An Nhiên Retail | OPEN | 500.00 | 0 | 0 |
| 8 | 2 | Tối ưu truy vấn báo cáo tồn kho Mộc Trà Studio | OPEN | 1200.00 | 1 | 0 |
| 22001 | 20001 | Xây dựng cổng đặt hàng cho Mộc Trà Commerce — chi nhánh trung tâm | IN_PROGRESS | 1800.00 | 2 | 1 |
| 22002 | 20002 | Phát triển ứng dụng đặt lịch cho Sen Xanh Services — chi nhánh trung tâm | IN_PROGRESS | 2400.00 | 2 | 1 |

### Q-02

Số dòng kết quả: 204.

```sql
SELECT freelancer_id,
       COUNT(*) AS proposals
FROM proposals
GROUP BY freelancer_id
HAVING COUNT(*) >= 2
ORDER BY freelancer_id
```

| freelancer_id | proposals |
| --- | --- |
| 4 | 3 |
| 6 | 3 |
| 7 | 2 |
| 8 | 2 |
| 21001 | 9 |
| 21002 | 9 |
| 21003 | 9 |
| 21004 | 9 |
| 21005 | 9 |
| 21006 | 9 |

### Q-03

Số dòng kết quả: 101.

```sql
SELECT j.job_id,
       j.title
FROM jobs AS j
WHERE NOT EXISTS
        (SELECT 1
         FROM proposals AS p
         WHERE p.job_id = j.job_id)
ORDER BY j.job_id
```

| job_id | title |
| --- | --- |
| 7 | Thiết kế trang giới thiệu bộ sưu tập An Nhiên Retail |
| 22901 | Xây dựng design system cho Thiên Lam Learning — nhóm chăm sóc khách hàng |
| 22902 | Kiểm tra chất lượng bản phát hành cho Bảo An Solutions — nhóm chăm sóc khách hàng |
| 22903 | Thiết lập môi trường staging cho Phố Nhỏ Cloud — nhóm chăm sóc khách hàng |
| 22904 | Viết hướng dẫn tích hợp API cho Tâm Việt Media — nhóm chăm sóc khách hàng |
| 22905 | Phát triển website giới thiệu sản phẩm cho Hạ Vàng Commerce — nhóm chăm sóc khách hàng |
| 22906 | Nâng cấp ứng dụng đặt dịch vụ cho Thu Hà Services — nhóm chăm sóc khách hàng |
| 22907 | Tích hợp dữ liệu đơn hàng cho Quỳnh Anh Logistics — nhóm chăm sóc khách hàng |
| 22908 | Phân tích tỷ lệ chuyển đổi cho Hồng Phúc Foods — nhóm chăm sóc khách hàng |
| 22909 | Xây dựng design system cho Lam Sơn Learning — nhóm chăm sóc khách hàng |

### Q-04

Số dòng kết quả: 204.

```sql
WITH totals AS
    (SELECT freelancer_id,
            SUM(total_amount) AS value
     FROM contracts
     WHERE status <> 'CANCELLED'
     GROUP BY freelancer_id)
SELECT freelancer_id,
       value,
       DENSE_RANK() OVER (
                          ORDER BY value DESC) AS value_rank
FROM totals
ORDER BY value_rank,
         freelancer_id
```

| freelancer_id | value | value_rank |
| --- | --- | --- |
| 21159 | 10740.00 | 1 |
| 21135 | 10680.00 | 2 |
| 21151 | 10650.00 | 3 |
| 21127 | 10590.00 | 4 |
| 21143 | 10560.00 | 5 |
| 21103 | 10290.00 | 6 |
| 21095 | 10200.00 | 7 |
| 21111 | 10170.00 | 8 |
| 21087 | 10110.00 | 9 |
| 21119 | 10050.00 | 10 |

### Q-05

Số dòng kết quả: 43.

```sql
SELECT *
FROM v_client_spend
ORDER BY client_id
```

| client_id | paid_count | paid_amount |
| --- | --- | --- |
| 1 | 2 | 700.00 |
| 2 | 1 | 200.00 |
| 3 | 0 | 0.00 |
| 20001 | 15 | 11970.00 |
| 20002 | 0 | 0.00 |
| 20003 | 0 | 0.00 |
| 20004 | 0 | 0.00 |
| 20005 | 45 | 26910.00 |
| 20006 | 15 | 9720.00 |
| 20007 | 0 | 0.00 |

### Q-06

Số dòng kết quả: 485.

```sql
SELECT contract_id,
       total_amount,
       paid_amount,
       outstanding_amount
FROM v_contract_overview
WHERE outstanding_amount > 0
ORDER BY contract_id
```

| contract_id | total_amount | paid_amount | outstanding_amount |
| --- | --- | --- | --- |
| 1 | 1000.00 | 400.00 | 600.00 |
| 2 | 800.00 | 300.00 | 500.00 |
| 3 | 1500.00 | 0.00 | 1500.00 |
| 4 | 600.00 | 200.00 | 400.00 |
| 5 | 2000.00 | 0.00 | 2000.00 |
| 6 | 1800.00 | 600.00 | 1200.00 |
| 7 | 2400.00 | 0.00 | 2400.00 |
| 8 | 2100.00 | 0.00 | 2100.00 |
| 9 | 1500.00 | 0.00 | 1500.00 |
| 11 | 1350.00 | 450.00 | 900.00 |

### Q-07

Số dòng kết quả: 483.

```sql
SELECT m.milestone_id,
       m.status,
       m.amount
FROM milestones AS m
WHERE m.status IN ('COMPLETED',
                   'APPROVED')
    AND NOT EXISTS
        (SELECT 1
         FROM payments AS p
         WHERE p.milestone_id=m.milestone_id
             AND p.payment_status='PAID')
ORDER BY m.milestone_id
```

| milestone_id | status | amount |
| --- | --- | --- |
| 2 | COMPLETED | 600.00 |
| 5 | APPROVED | 500.00 |
| 9 | APPROVED | 500.00 |
| 26002 | COMPLETED | 600.00 |
| 26004 | APPROVED | 800.00 |
| 26007 | APPROVED | 700.00 |
| 26010 | COMPLETED | 500.00 |
| 26017 | COMPLETED | 450.00 |
| 26019 | APPROVED | 900.00 |
| 26022 | APPROVED | 300.00 |

### Q-08

Số dòng kết quả: 494.

```sql
SELECT job_id,
       budget_max
FROM jobs
WHERE budget_max >
        (SELECT AVG(budget_max)
         FROM jobs)
ORDER BY job_id
```

| job_id | budget_max |
| --- | --- |
| 22002 | 2400.00 |
| 22007 | 2700.00 |
| 22010 | 2430.00 |
| 22015 | 2730.00 |
| 22018 | 2460.00 |
| 22023 | 2760.00 |
| 22026 | 2490.00 |
| 22031 | 2790.00 |
| 22034 | 2520.00 |
| 22039 | 2820.00 |

### Q-09

Số dòng kết quả: 202.

```sql
SELECT f.freelancer_id,
       f.professional_title,
       COUNT(fs.skill_id) AS skill_count
FROM freelancers AS f
INNER JOIN freelancer_skills AS fs ON fs.freelancer_id=f.freelancer_id
GROUP BY f.freelancer_id,
         f.professional_title
HAVING COUNT(fs.skill_id)>=3
ORDER BY f.freelancer_id
```

| freelancer_id | professional_title | skill_count |
| --- | --- | --- |
| 4 | Lập trình viên Python và cơ sở dữ liệu | 3 |
| 6 | Chuyên viên dữ liệu và báo cáo | 3 |
| 21001 | Lập trình viên web full stack | 3 |
| 21002 | Lập trình viên ứng dụng di động | 3 |
| 21003 | Kỹ sư dữ liệu | 3 |
| 21004 | Chuyên viên phân tích dữ liệu | 3 |
| 21005 | Nhà thiết kế sản phẩm số | 3 |
| 21006 | Kỹ sư kiểm thử phần mềm | 3 |
| 21007 | Kỹ sư DevOps và đám mây | 3 |
| 21008 | Chuyên viên tài liệu kỹ thuật | 3 |

### Q-10

Số dòng kết quả: 605.

```sql
SELECT *
FROM v_contract_overview
ORDER BY contract_id
```

| contract_id | client_id | freelancer_id | total_amount | status | milestone_count | allocated_amount | paid_amount | outstanding_amount |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 4 | 1000.00 | ACTIVE | 2 | 1000.00 | 400.00 | 600.00 |
| 2 | 1 | 5 | 800.00 | ACTIVE | 2 | 800.00 | 300.00 | 500.00 |
| 3 | 2 | 6 | 1500.00 | ACTIVE | 2 | 1500.00 | 0.00 | 1500.00 |
| 4 | 2 | 7 | 600.00 | ACTIVE | 2 | 600.00 | 200.00 | 400.00 |
| 5 | 3 | 4 | 2000.00 | ACTIVE | 2 | 2000.00 | 0.00 | 2000.00 |
| 6 | 20001 | 21001 | 1800.00 | ACTIVE | 3 | 1800.00 | 600.00 | 1200.00 |
| 7 | 20002 | 21002 | 2400.00 | ACTIVE | 3 | 2400.00 | 0.00 | 2400.00 |
| 8 | 20003 | 21003 | 2100.00 | ACTIVE | 3 | 2100.00 | 0.00 | 2100.00 |
| 9 | 20004 | 21004 | 1500.00 | ACTIVE | 3 | 1500.00 | 0.00 | 1500.00 |
| 10 | 20005 | 21005 | 1200.00 | COMPLETED | 3 | 1200.00 | 1200.00 | 0.00 |

### Q-11

Số dòng kết quả: 40.

```sql
WITH counts AS
    (SELECT client_id,
            COUNT(*) AS job_count
     FROM jobs
     GROUP BY client_id),
     ranked AS
    (SELECT *,
            DENSE_RANK() OVER (
                               ORDER BY job_count DESC) AS r
     FROM counts)
SELECT client_id,
       job_count
FROM ranked
WHERE r=1
ORDER BY client_id
```

| client_id | job_count |
| --- | --- |
| 20001 | 25 |
| 20002 | 25 |
| 20003 | 25 |
| 20004 | 25 |
| 20005 | 25 |
| 20006 | 25 |
| 20007 | 25 |
| 20008 | 25 |
| 20009 | 25 |
| 20010 | 25 |

### Q-12

Số dòng kết quả: 125.

```sql
SELECT c.contract_id,
       COUNT(m.milestone_id) AS overdue_work
FROM contracts AS c
JOIN milestones AS m ON m.contract_id=c.contract_id
WHERE c.status='ACTIVE'
    AND m.status IN ('PENDING',
                     'IN_PROGRESS',
                     'COMPLETED')
    AND m.due_date < DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY c.contract_id
ORDER BY c.contract_id
```

| contract_id | overdue_work |
| --- | --- |
| 1 | 1 |
| 2 | 1 |
| 3 | 1 |
| 4 | 1 |
| 5 | 1 |
| 9 | 1 |
| 14 | 1 |
| 19 | 1 |
| 24 | 1 |
| 29 | 1 |
