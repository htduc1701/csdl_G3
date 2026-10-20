# Sơ đồ của bản báo cáo mới

- `01_overview`: đầy đủ 12 entities, các key chính và multiplicity.
- `02_accounts`: user/subtypes và skill association.
- `03_agreements`: job, category, proposal và contract.
- `04_delivery`: contract, milestone, payment attempt và review.

`.dot` là nguồn có thể sửa; `.svg` là hình vector; `.png` dùng trong Word. Graphviz có thể xuất lại bằng `dot -Tsvg 01_overview.dot -o 01_overview.svg` nếu đã cài công cụ đó. Nhãn multiplicity đặt tại từng đầu association. USER specialization phải đọc cùng ghi chú total/disjoint; hai optional identity links riêng không đủ diễn đạt invariant đó.

Sơ đồ dùng UML-style class compartments và association multiplicity; dictionary và DDL cung cấp kiểu dữ liệu, default, CHECK và functional unique indexes đầy đủ. Không thêm thực thể mới khi tách một sơ đồ thành các hình theo nhóm nghiệp vụ; các node lặp ở hình chi tiết vẫn chỉ là cùng bảng.
