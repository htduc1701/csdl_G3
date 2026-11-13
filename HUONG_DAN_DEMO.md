# Cài Mini Upwork G3 và trình bày trên Windows

## 1. Chuẩn bị

- **MySQL Server**. Dự án nhắm tới MySQL 8.0.42. Ghi lại mật khẩu root bạn đặt khi cài và cổng của server, thường là 3306. Nếu máy đã có MySQL, dùng thông tin của dịch vụ đang chạy.
- **MySQL Workbench** để chạy các file SQL. Kiểm tra kết nối với host `localhost`, cổng của server và user `root`. Mục **Store Password** lưu mật khẩu cho Workbench. Mật khẩu của server được đặt lúc cài MySQL hoặc đổi bằng `ALTER USER`.
- **Python**. Python 3.13 là phiên bản đã dùng cho bản chạy demo. Trong PowerShell, chạy `python --version` để kiểm tra.

Thực hành trên một MySQL instance mới nếu bạn cần trình bày từ bước cài schema. Nếu instance đang có schema `mini_upwork` chứa dữ liệu cần giữ, dùng schema hiện có để chạy web hoặc dùng một instance riêng để thực hành cài mới.

## 2. Cài đủ schema và dữ liệu

1. Mở kết nối quản trị trong Workbench. Mở file [INSTALL_DATABASE.sql](INSTALL_DATABASE.sql) bằng **File → Open SQL Script** và chạy toàn bộ file. Dừng tại lỗi đầu tiên nếu Workbench báo lỗi.
2. Script tạo bảng, trigger, view, index, procedure, tài khoản và nạp cả bộ dữ liệu mẫu. Làm mới **Schemas** để thấy `mini_upwork`. Phần cuối script kiểm đếm **11 bảng nghiệp vụ, 7.223 dòng dữ liệu, 1.008 jobs** trước khi phát sinh dữ liệu demo. Có thể chạy riêng [sql/09_verify_counts.sql](sql/09_verify_counts.sql) để hiện lại kết quả.
3. Trong cùng kết nối quản trị, chạy toàn bộ [SETUP_LOCAL_DEMO.sql](SETUP_LOCAL_DEMO.sql). File đặt mật khẩu mẫu và mở khóa đúng ba tài khoản dùng trong web demo. Sau bước này, Client ID **1**, Freelancer ID **4** và tài khoản ghi nhận thanh toán có thể thực hiện các thao tác tương ứng.
4. Khi trình bày phần truy vấn SQL, mở [sql/06_queries.sql](sql/06_queries.sql) và chạy các câu SELECT cần minh họa.

File cài tổng hợp đã bao gồm dữ liệu trong `SAMPLE_DATA.sql`. Chọn một cách cài để tránh nạp trùng. Nếu gặp lỗi giữa chừng, giữ lại thông báo lỗi và kiểm tra phần đã chạy trước khi thử lại trên instance dùng để thực hành.

## 3. Cài thư viện và chạy Flask

Mở **PowerShell** tại thư mục chứa `main.py`. Đổi đường dẫn ở dòng đầu nếu bạn chép dự án sang máy khác. Dùng trực tiếp Python trong môi trường ảo để khỏi cần đổi Execution Policy.

```powershell
Set-Location 'D:\csdl\csdl_G3\Freelance_Marketplace_Ecosystem_SQL'
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
$env:DB_HOST = 'localhost'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$env:DB_PASSWORD = Read-Host 'Nhap mat khau MySQL root' -MaskInput
.\.venv\Scripts\python.exe main.py
```

Nếu PowerShell cũ báo không có tham số `-MaskInput`, dùng PowerShell 7 hoặc nhập `$env:DB_PASSWORD = Read-Host 'Nhap mat khau MySQL root'` trong cửa sổ riêng khi chưa chiếu màn hình. Mật khẩu phải khớp với kết nối Workbench. Khi dùng một cửa sổ PowerShell mới, đặt lại các biến kết nối trước khi chạy Flask. Giữ cửa sổ mở và vào [http://127.0.0.1:5000](http://127.0.0.1:5000). Nhấn `Ctrl+C` để dừng.

## 4. Kịch bản trình bày

Mở hai tab, [Client](http://127.0.0.1:5000/client) và [Freelancer](http://127.0.0.1:5000/freelancer). Dùng một tên job riêng để dễ nhận ra giữa dữ liệu mẫu.

| Bước | Thao tác trên web | Dữ liệu và kết quả cần thấy |
|---|---|---|
| 1 | Client → **Post Job** | Client ID **1**, chọn danh mục, nhập tên và mô tả. Budget **100–200**. Để trống deadline hoặc chọn từ ngày mai. Ghi lại ID job. |
| 2 | Freelancer → mở job vừa tạo → gửi proposal | Freelancer ID **4**, đề xuất **150**, Estimated Days **7**, nhập cover letter. |
| 3 | Client → job vừa tạo → xem proposals → chọn đề xuất của Freelancer 4 | Proposal chuyển sang `CLIENT_ACCEPTED`. |
| 4 | Freelancer → **My Proposals** → xác nhận proposal đó | Proposal chuyển sang `CONFIRMED`. Hợp đồng được tạo và job chuyển sang `IN_PROGRESS`. |
| 5 | Client → **My Contracts** → mở milestones của hợp đồng vừa tạo | Tên milestone tùy bạn, Amount **150**. Có thể để trống Due Date hoặc chọn trong khoảng ngày biểu mẫu hiển thị. |
| 6 | Freelancer → **My Milestones** → bắt đầu, sau đó hoàn thành | Milestone chuyển `PENDING` → `IN_PROGRESS` → `COMPLETED`. |
| 7 | Client → mở lại milestone → **Approve** | Milestone chuyển `APPROVED`. Tải lại trang nếu tab Client đang mở từ trước. |
| 8 | Client → **Record Payment** → chọn Bank Transfer và Paid | Web ghi nhận thanh toán mô phỏng với trạng thái `PAID`. |
| 9 | Mở [Reports](http://127.0.0.1:5000/reports) | Đối chiếu job, hợp đồng và số tiền đã ghi nhận. |

## 5. Xử lý nhanh khi gặp lỗi

| Hiện tượng | Kiểm tra và xử lý |
|---|---|
| Workbench hoặc Flask báo `Access denied` cho root | Kiểm tra user, cổng và mật khẩu trên đúng MySQL Server. Nếu Workbench đăng nhập được, dùng cùng mật khẩu cho `DB_PASSWORD` và khởi động lại Flask. |
| Báo không kết nối được cổng 3306 | Kiểm tra dịch vụ MySQL trong `services.msc` và dùng cùng cổng ở Workbench và `DB_PORT`. |
| Báo `Unknown database 'mini_upwork'` | Kiểm tra bạn đã chạy `INSTALL_DATABASE.sql` trên chính server và cổng mà Flask đang dùng. |
| Báo thiếu `flask` hoặc `mysql.connector` | Cài lại bằng `.\.venv\Scripts\python.exe -m pip install -r requirements.txt`, rồi chạy app bằng cùng Python đó. |
| Báo tài khoản Client, Freelancer hoặc Payment bị từ chối | Kiểm tra đã chạy `SETUP_LOCAL_DEMO.sql` đúng instance và dùng Client **1**, Freelancer **4** cho luồng trình bày. |
| Không thấy hợp đồng | Vào **My Proposals** của Freelancer và xác nhận đề xuất mà Client vừa chọn. |
| Đăng job báo lỗi ngày hoặc ngân sách | Deadline để trống hoặc từ ngày mai. Nhập ngân sách không âm và mức tối đa lớn hơn hoặc bằng mức tối thiểu. |
| Thêm milestone báo lỗi ngày hoặc ngân sách | Dùng Due Date trong khoảng ngày hợp đồng, hoặc để trống. Amount phải dương và không vượt **Remaining budget**. |
| Cổng web 5000 đang được dùng | Dừng tiến trình Flask cũ trong PowerShell của nó. Nếu cần chạy cổng khác, dùng `.\.venv\Scripts\python.exe -m flask --app main run --port 5001` và mở cổng 5001. |
| Trình duyệt báo lỗi 500 | Xem dòng lỗi cuối cùng trong cửa sổ PowerShell đang chạy Flask. Ghi lại thao tác và ID job, proposal hoặc hợp đồng để xác định đúng bản ghi. |
