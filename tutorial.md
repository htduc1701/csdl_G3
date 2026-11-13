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

Thực hiện các bước dưới đây trong **cùng một cửa sổ PowerShell**.

### 3.1. Mở thư mục dự án

Chạy từng dòng. Đổi đường dẫn ở dòng đầu nếu bạn chép dự án sang máy khác.

```powershell
Set-Location 'D:\csdl\csdl_G3\Freelance_Marketplace_Ecosystem_SQL'
Get-Item main.py, requirements.txt
python --version
```

PowerShell sẽ hiện tên hai file và phiên bản Python. Nếu thiếu file, kiểm tra lại đường dẫn. Nếu lệnh `python` chưa được nhận diện, cài Python hoặc kiểm tra cấu hình PATH rồi mở lại PowerShell.

### 3.2. Tạo môi trường Python và cài thư viện

Chạy hai lệnh này khi cài lần đầu.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Đợi đến khi dấu nhắc `PS ...>` xuất hiện lại. Dòng `Requirement already satisfied` cho biết thư viện đã có. Các lệnh trong hướng dẫn gọi thẳng Python trong `.venv` nên bạn có thể chạy ngay mà không cần kích hoạt môi trường hay đổi Execution Policy.

### 3.3. Nhập thông tin kết nối MySQL

Mở `services.msc` và kiểm tra dịch vụ MySQL đang chạy. Trên máy đã dùng để demo, dịch vụ có tên **MySQL267**. Nếu máy trình bày dùng cổng khác, đặt `DB_PORT` theo cổng trong kết nối Workbench.

```powershell
$env:DB_HOST = 'localhost'
$env:DB_PORT = '3306'
$env:DB_USER = 'root'
$env:DB_PASSWORD = Read-Host 'Nhap mat khau MySQL root' -MaskInput
```

Giữ nguyên dòng `Read-Host`. Khi PowerShell hiện `Nhap mat khau MySQL root`, nhập mật khẩu root hiện tại của MySQL rồi nhấn **Enter**. Nhập đúng từng ký tự và tránh thêm dấu cách. Nếu PowerShell báo không hỗ trợ `-MaskInput`, chạy dòng dưới đây. Với cách này, ký tự bạn gõ sẽ hiện trên màn hình, nên hãy nhập trước khi trình chiếu.

```powershell
$env:DB_PASSWORD = Read-Host 'Nhap mat khau MySQL root'
```

### 3.4. Chạy Flask và mở web

Vẫn trong cùng cửa sổ PowerShell, chạy lệnh sau.

```powershell
.\.venv\Scripts\python.exe main.py
```

Khi thấy `Running on http://127.0.0.1:5000`, mở [Mini Upwork](http://127.0.0.1:5000) trong trình duyệt. Giữ PowerShell mở khi demo. Nhấn `Ctrl+C` để dừng web.

Nếu báo `ModuleNotFoundError`, chạy lại lệnh cài thư viện ở bước 3.2 rồi dùng đúng Python trong `.venv`. Nếu báo `Access denied` cho root, kiểm tra mật khẩu và cổng bằng Workbench, nhập lại thông tin ở bước 3.3 rồi chạy lại Flask.

Sau khi tắt rồi bật máy, nếu đã cài database và còn thư mục `.venv`, làm lại bước 3.1, 3.3 và 3.4. Các biến kết nối cần được đặt lại trong mỗi cửa sổ PowerShell mới.

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
