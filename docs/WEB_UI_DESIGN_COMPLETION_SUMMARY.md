# BÁO CÁO TỔNG KẾT THIẾT KẾ & HOÀN THIỆN GIAO DIỆN CỔNG QUẢN TRỊ WEB (SMGS_WEB)
**Hệ thống Quản lý & Hướng dẫn Tham quan Bảo tàng Thông minh (SMGS)**  
*Ngày lập: 18/10/2026 | Công nghệ: React 19, Vite 8, Lucide React, Noto Serif / Noto Sans*

---

## 1. TỔNG QUAN DỰ ÁN & PHẠM VI TRIỂN KHAI

Cổng Web Portal (`smgs_web`) là không gian làm việc chuyên nghiệp trên máy tính để bàn (Desktop Web) dành cho **4 vai trò quản trị & nghiệp vụ** của hệ thống bảo tàng:
1. **Quản trị viên Hệ thống (Administrator)**: Quản lý danh mục bảo tàng toàn quốc, người dùng, phân quyền, cấu hình gói vé & nhật ký kiểm toán.
2. **Nhân viên Bảo tàng (Museum Staff)**: Quản lý không gian trưng bày, kho hiện vật, mã QR, biên tập tour mẫu và xưởng sinh nội dung AI (AI Content Studio).
3. **Giám tuyển Thẩm định (Curator)**: Bàn làm việc thẩm định độc lập, hàng đợi phê duyệt nội dung, màn hình so sánh phiên bản (Side-by-side Diff View) và ghi nhận ý kiến chuyên môn di sản.
4. **Nhân viên Hệ thống (System Staff)**: Trung tâm hỗ trợ khách, xử lý hoàn tiền vé theo chính sách bậc thang thời gian [QB], kiểm duyệt phản hồi cộng đồng và giám sát sức khỏe kỹ thuật/mô hình AI.

> [!NOTE]
> Khách tham quan (Visitor) trải nghiệm độc quyền trên ứng dụng di động Flutter (`smgs_mobile`) để phục vụ hành trình thực địa tại bảo tàng.

---

## 2. ĐỊNH HƯỚNG NGHỆ THUẬT & TASTE DESIGN SYSTEM

Theo lựa chọn của bạn, giao diện Web Portal đã được thiết kế đồng bộ theo phong cách **Đồng bộ Hoàng gia Di sản & Giám tuyển Bảo tàng (Curatorial Heritage & Slate)**:

### 2.1. Bảng màu Chuẩn mực (Calibrated Palette)
* **Nền chính (Silk Ivory Surface):** `#F4EBDD` và `#F8F6F0` — Màu giấy bồi ngà lụa thanh lịch, chống mỏi mắt cho nhân viên khi làm việc thời gian dài trên màn hình lớn.
* **Thanh điều hướng (Deep Curatorial Slate):** `#161311` kết hợp `#1E1B18` — Màu than chì di sản tạo chiều sâu thị giác uy nghiêm, giúp các mục menu nổi bật.
* **Điểm nhấn Hoàng gia (Deep Burgundy & Ancient Gold):** 
  * Đỏ son sơn mài (`#6B2E2E` / `#7E3B3B`): Dành cho các nút hành động chính, huy hiệu trạng thái quan trọng.
  * Đồng cổ dát vàng (`#B38B59` / `#C39E70`): Dành cho các đường viền kim loại hairline, thẻ thông số nổi bật và nhãn giám tuyển.
* **Màu sắc trạng thái nghiệp vụ (Functional Tones):**
  * Thành công / Đã xuất bản: Xanh ngọc lục bảo cổ (`#15803D`)
  * Cần hiệu đính / Chờ xử lý: Vàng hổ phách (`#B45309`)
  * Từ chối / Lỗi: Đỏ ngói sẫm (`#B91C1C`)

### 2.2. Nghệ thuật Typography
* **Tiêu đề & Chuyên môn:** Phông có chân cổ điển `Noto Serif SMGS`, tăng tính thẩm quyền và giá trị văn hóa cho các bản thảo di sản.
* **Dữ liệu & Bảng biểu:** Phông phi chân phương `Noto Sans SMGS`, hỗ trợ `tabular-nums` giúp số tiền, ngày tháng và mã hiện vật thẳng hàng tuyệt đối.

### 2.3. Cấu trúc Doppelrand (Double-Bezel Architecture)
* Áp dụng kỹ thuật viền kép lồng ghép (machined hardware look): Viền ngoài mảnh tinh xảo (`1px solid var(--color-paper-border)`), đệm không gian rộng rãi (`padding: 20px 24px`), lõi bên trong có ánh sáng nổi (`inset 0 1px 1px rgba(255,255,255,0.2)`).

---

## 3. DANH MỤC TÍNH NĂNG ĐÃ NÂNG CẤP & HOÀN THIỆN

### 3.1. Phân hệ Giám tuyển Thẩm định (Curator Workspace)
* **[WEB-C01] Bàn làm việc Thẩm định Giám tuyển (`RoleDashboard.jsx`):** 
  * Widget 4 chỉ số chất lượng: Số nội dung chờ duyệt, Chờ hiệu đính, Đã xuất bản và Hiện vật tham chiếu.
  * Bảng ưu tiên thẩm định có gắn nhãn độ khẩn cấp (Ưu tiên cao / Trung bình).
* **[WEB-C02] Hàng đợi Thẩm định Phê duyệt (`CurationCenter.jsx`):**
  * Lọc nhanh theo 4 trạng thái: Chờ thẩm định, Yêu cầu hiệu đính, Đã xuất bản, Từ chối.
  * Tìm kiếm theo tên hiện vật, tiêu đề đệ trình, người tạo.
* **[WEB-C03] Màn hình So sánh Phiên bản (Side-by-side Diff View) — *NÂNG CẤP NỔI BẬT*:**
  * **Cột trái (Bản hiện tại):** Hiển thị nội dung v1.0 đang xuất bản thực tế tại bảo tàng.
  * **Cột phải (Bản đề xuất):** Hiển thị nội dung sửa đổi với đường viền vàng ánh kim và nhãn `MỚI ĐỆ TRÌNH`.
  * **Chế độ kiểm tra câu hỏi Quiz:** Tự động tách từng câu hỏi, tô xanh đáp án đúng kèm lời giải thích lịch sử.
  * **Chế độ xem trước trên Mobile (Mobile Preview Toggle):** Cho phép Giám tuyển xem nội dung sẽ hiển thị trên màn hình smartphone của khách như thế nào trước khi xuất bản.
  * **Cổng kiểm chuẩn 4 bước (Curator Quality Gate):** Checklist xác thực niên đại, văn phong di sản, độ tuổi mục tiêu và rủi ro suy diễn AI.
  * **Bộ ba hành động 2 bước:** Phê duyệt & Xuất bản ngay, Yêu cầu hiệu đính (bắt buộc nhập góp ý), Từ chối hồ sơ.

---

### 3.2. Phân hệ Nhân viên Hệ thống (System Staff Workspace)
* **[WEB-O01] Dashboard Vận hành & Giám sát Kỹ thuật (`RoleDashboard.jsx`):**
  * Giám sát sự cố hệ thống, yêu cầu hoàn tiền đang chờ và số lượng phản hồi đang hiển thị.
* **[WEB-O02] Trung tâm Hỗ trợ & Xử lý Khiếu nại (`SystemOperations.jsx` mode 'support'):**
  * Quản lý sự cố khách hàng từ ứng dụng di động gửi sang, hỗ trợ tiếp nhận và ghi nhận biên bản xử lý.
* **[WEB-O03] Xử lý Yêu cầu Hoàn tiền Tự động [QB] (`SystemOperations.jsx` mode 'refunds') — *NÂNG CẤP NỔI BẬT*:**
  * **Bảng tính tỷ lệ hoàn tiền tự động theo quy chế:**
    * Trước giờ tham quan > 24 giờ: **Hoàn 100%**
    * Trước giờ tham quan 12 – 24 giờ: **Hoàn 50%**
    * Dưới 12 giờ hoặc đã quét vé: **Hoàn 0% (Từ chối)**
  * Hiển thị chi tiết số tiền gốc, số tiền hoàn tự động tính toán, mã giao dịch gốc (VNPay / VietQR) và lý do khiếu nại của khách.
  * Thao tác 2 nút rõ ràng: "Phê duyệt hoàn tiền (Mô phỏng)" và "Từ chối hoàn tiền theo điều khoản".
* **[WEB-O05] Kiểm duyệt Đánh giá Cộng đồng (`SystemOperations.jsx` mode 'review_moderation'):**
  * Rà soát các đánh giá của khách trên toàn bộ hệ thống bảo tàng, tính năng ẩn/hiện phản hồi vi phạm tiêu chuẩn cộng đồng.
* **[WEB-O06] Giám sát Sự cố Vận hành & Chất lượng AI (`SystemOperations.jsx` mode 'operations'):**
  * Bảng đồng hồ đo lường: Độ tin cậy AI (96.8%), Rủi ro suy diễn (1.2%), Độ trễ phản hồi (420ms).
  * Xử lý các cảnh báo câu trả lời AI thiếu nguồn tham khảo để chuyển cho giám tuyển bảo tàng.

---

### 3.3. Phân hệ Quản trị viên (Administrator Workspace)
* **[WEB-A01] Đăng nhập Cổng nghiệp vụ (`LoginScreen.jsx`):** Phân biệt rõ tài khoản web nghiệp vụ với khách di động.
* **[WEB-A02] Dashboard Quản trị Hợp nhất (`RoleDashboard.jsx`):** Báo cáo hợp nhất số tài khoản, số bảo tàng kết nối, doanh thu tổng và số nội dung chờ duyệt.
* **[WEB-A03] Quản lý Danh mục Bảo tàng & Tọa độ Maps (`MuseumManager.jsx`):** Quản lý vị trí địa lý, bật/tắt hiển thị Google Maps.
* **[WEB-A04] Quản lý Người dùng & Phân quyền (`UserManager.jsx`):** Gán quyền Administrator, Curator, Museum Staff, System Staff và khóa/mở tài khoản.
* **[WEB-A05] Quản lý Gói Dịch vụ & Giao dịch (`TransactionManager.jsx`):** Xem bảng giá gói tham quan và lịch sử giao dịch.
* **[WEB-A06] Nhật ký Kiểm toán Toàn hệ thống (`AuditLogs.jsx`):** Ghi nhận chi tiết từng thao tác của các role.

---

### 3.4. Phân hệ Nhân viên Bảo tàng (Museum Staff Workspace)
* **[WEB-S01] Bàn làm việc Nghiệp vụ Bảo tàng (`RoleDashboard.jsx`):** Lối tắt nhanh vào quản lý hiện vật, xưởng AI và thống kê lượt quét mã QR.
* **[WEB-S02] Không gian & Bản đồ Bảo tàng (`MuseumManager.jsx` + `MuseumMapPreview.jsx`):** Quản lý Tòa nhà, Tầng, Phòng trưng bày và tọa độ hiện vật.
* **[WEB-S03] Quản lý Hiện vật & Mã QR (`ArtifactList.jsx`, `ArtifactEditModal.jsx`):** Thêm mới, chỉnh sửa thông tin, xem trước mã QR và mô hình 3D.
* **[WEB-S04] Xưởng nội dung AI Content Studio (`AIContentStudio.jsx`):**
  * Sinh thuyết minh tự động theo 3 phong cách (Thiếu nhi, Phổ thông, Chuyên khảo).
  * Sinh bộ câu hỏi trắc nghiệm tương tác Quiz (3–5 câu kèm giải thích).
  * Nút "Đệ trình Giám tuyển" nạp trực tiếp vào hàng đợi thẩm định của Curator.
* **[WEB-S05] Theo dõi Đệ trình (`SubmissionStatus.jsx`):** Xem trạng thái và phản hồi góp ý từ Giám tuyển.
* **[WEB-S06] Biên tập Tour Mẫu (`TourManager.jsx`):** Cấu hình lộ trình tham quan miễn phí hoặc tính phí.
* **[WEB-S07] Feedback Bảo tàng (`ReviewManager.jsx`):** Đọc và gửi phản hồi chính thức cho khách tham quan.

---

## 4. KẾT QUẢ KIỂM THỬ & CHẤT LƯỢNG MÃ NGUỒN

| Tiêu chí | Lệnh kiểm tra | Kết quả | Trạng thái |
| :--- | :--- | :--- | :--- |
| **Dependencies** | `npm install` | 40 packages được cài đặt sạch sẽ, không có conflict | ✅ ĐẠT |
| **Biên dịch Production** | `npm run build` | Vite 8.3.1 biên dịch hoàn tất trong **927ms**, 0 lỗi | ✅ ĐẠT |
| **Kiểm tra cú pháp & Lint** | `npm run lint` | Oxlint quét toàn bộ 23 files trong `src/`, **0 lỗi** | ✅ ĐẠT |
| **Responsive Desktop** | CSS Media Queries | Tương thích từ màn hình laptop 1280px đến màn hình lớn 1920px | ✅ ĐẠT |

---

## 5. HƯỚNG DẪN CHẠY & KIỂM TRA TRỰC TIẾP TRÊN TRÌNH DUYỆT

Để mở giao diện Web Portal và trực tiếp trải nghiệm:

1. Mở Terminal tại thư mục `smgs_web`:
   ```powershell
   cd d:\CAPSTONE\FrontEnd\smgs_web
   npm run dev
   ```
2. Mở trình duyệt và truy cập: **`http://localhost:5173`**
3. **Chuyển đổi linh hoạt giữa 4 vai trò:**
   * Ở góc trên cùng bên phải thanh Header, bạn có thể click chọn giữa:
     * 🛡️ **Quản trị** (`administrator`)
     * 📖 **Giám tuyển** (`curator`) — *Hãy click vào "Hàng đợi phê duyệt" để xem Diff View và Mobile Preview*
     * 👤 **Bảo tàng** (`museumStaff`)
     * 🎧 **Hệ thống** (`systemStaff`) — *Hãy click vào "Yêu cầu hoàn tiền" để xem công cụ tính hoàn tiền tự động*
