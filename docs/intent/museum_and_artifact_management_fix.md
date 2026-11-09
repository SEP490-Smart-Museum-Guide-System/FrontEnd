# Statement of Intent: Cải tiến Quản lý Bảo tàng, Cấu trúc Không gian & Hiện vật

- **Dự án**: Smart Museum Guide System (SMGS) - SEP490
- **Ngày xác nhận**: 09/11/2026
- **Tài liệu căn cứ**: `Fix.txt`

---

## 1. Bản mô tả mục tiêu (Statement of Intent)

- **Outcome**: 
  1. Soạn thảo hướng dẫn và mã nguồn Backend C# chi tiết để tạo Tòa nhà chính & Tầng trệt tự động trong 1 Database Transaction khi System Admin tạo bảo tàng mới, bàn giao cho team Backend.
  2. Triển khai hoàn chỉnh toàn bộ giao diện Frontend (`smgs_web`) theo đúng phân quyền mới: loại bỏ dropdown "Quyền truy cập" khi thêm hiện vật, đổi tên menu System Admin thành "Quản lý bảo tàng" với chức năng phân công nhân viên tìm kiếm theo tên/email, tạo trang "Cấu trúc bảo tàng" dạng cây phân cấp cho Museum Staff.
- **User**: 
  - **FE Developer**: Đồng bộ code chuẩn hóa với BE.
  - **System Admin**: Quản trị danh sách bảo tàng, phân công nhân viên thuận tiện không cần nhớ UUID.
  - **Museum Staff**: Quản lý cấu trúc bảo tàng (Tòa nhà $\rightarrow$ Tầng $\rightarrow$ Phòng trưng bày) và sơ đồ trực quan.
- **Why now**: Phía BE đang cập nhật cấu trúc; FE cần dọn dẹp các form trùng lặp, tách bạch quyền hạn giữa System Admin và Museum Staff, nâng cao tính chuyên nghiệp và tính bảo toàn dữ liệu.
- **Success Criteria**:
  1. Tài liệu Backend patch rõ ràng, bao gồm file path, DTO, transaction logic rollback, code mẫu copy-paste được.
  2. Form "Thêm hiện vật" trên FE không còn trường "Quyền truy cập", layout liền mạch, mặc định gửi `free`.
  3. Menu System Admin đổi thành *"Quản lý bảo tàng"*, modal phân công nhân viên cho phép tìm kiếm theo tên/email và chọn từ danh sách thay vì gõ UUID thủ công.
  4. Màn hình *"Cấu trúc bảo tàng"* riêng cho Museum Staff hiển thị dạng cây phân cấp trực quan, modal riêng cho từng thao tác thêm/sửa/xóa, liên kết quản lý sơ đồ tầng.
- **Constraints**: 
  - Không chỉnh sửa trực tiếp vào file mã nguồn trong thư mục `BackEnd/` (soạn code để user chuyển cho dev BE).
  - Tái sử dụng trọn vẹn các API hiện có ở BE (`IndoorMapsController`, `AccountsController`, `MuseumsController`, `ArtifactsController`).
  - Không xóa cột hay làm xáo trộn dữ liệu hiện có trong DB.
- **Out of scope**: 
  - Chưa hỗ trợ khu trưng bày ngoài trời không thuộc tòa nhà.
  - Chưa tạo thêm vai trò mới (Museum Manager).
  - Chưa thay đổi database migration schema.

---

## 2. Kế hoạch phân rã công việc (Task Breakdown)

### Phần A: Soạn thảo Code Patch cho Backend
- **File mục tiêu ở BE**: `SMGS.Application/Services/MuseumService.cs` và `SMGS.Infrastructure/Data/MuseumRepository.cs` (hoặc `AppDbContext`).
- **Nội dung**: Bổ sung logic trong `CreateAsync` của `MuseumService.cs`:
  - Mở transaction (`IDbContextTransaction`).
  - Tạo `Museum`.
  - Tự động tạo `Building` với `Name = "Tòa nhà chính"`.
  - Tự động tạo `Floor` với `BuildingId`, `LevelNo = 0`, `Name = "Tầng trệt"`.
  - Commit transaction; nếu có lỗi thì rollback.
- **Tài liệu xuất ra**: `docs/BE_PATCH_AUTO_BUILDING_FLOOR.md`.

### Phần B: Cải tiến Form "Thêm hiện vật" (Frontend `smgs_web`)
- **File**: `smgs_web/src/components/artifacts/ArtifactEditModal.jsx` và `ArtifactList.jsx`.
- **Nội dung**:
  - Xóa dropdown "Quyền truy cập" (`accessLevel`).
  - Giữ giá trị mặc định gửi lên API là `'free'`.
  - Tinh chỉnh CSS grid/flex để không để lại khoảng trống trắng.

### Phần C: Cải tiến Menu & Trang "Quản lý bảo tàng" của System Admin
- **File**: `smgs_web/src/components/layout/Sidebar.jsx`, `MuseumManager.jsx`, `App.jsx`.
- **Nội dung**:
  - Đổi tên mục menu: `"Bảo tàng & Google Maps"` $\rightarrow$ `"Quản lý bảo tàng"`.
  - Ẩn các khu vực tạo tòa nhà, tạo tầng, tạo phòng trưng bày khỏi giao diện của System Admin.
  - Tinh chỉnh modal Phân công nhân viên: Thêm ô tìm kiếm tài khoản theo keyword (tên, email) gọi API `/api/admin/accounts?role=museum_staff&keyword=...`, hiển thị dropdown danh sách nhân viên để chọn thay vì nhập UUID.

### Phần D: Tạo trang "Cấu trúc bảo tàng" dạng cây phân cấp cho Museum Staff
- **File**: Tạo mới `smgs_web/src/components/museums/MuseumStructureTree.jsx` (hoặc nâng cấp `StructureManager.jsx`).
- **Nội dung**:
  - Giao diện cây phân cấp: Bảo tàng $\rightarrow$ Danh sách Tòa nhà $\rightarrow$ Danh sách Tầng $\rightarrow$ Danh sách Phòng trưng bày.
  - Mỗi nhánh có nút Thêm / Sửa / Xóa đối tượng tương ứng.
  - Thao tác thêm/sửa được mở qua Modal riêng biệt, không hiển thị đồng thời nhiều form dài gây rối.
  - Tích hợp nút chuyển nhanh sang quản lý sơ đồ tầng (`indoor_maps`) tương ứng.
  - Cảnh báo xác nhận khi xóa tòa nhà/tầng/phòng để bảo toàn dữ liệu hiện vật.
- **Sidebar & Routing**:
  - Đối với `museumStaff`: Bổ sung menu item *"Cấu trúc bảo tàng"* dẫn vào trang cây phân cấp này.
