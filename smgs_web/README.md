# SMGS Web Portal — Cổng Quản Trị & Nghiệp Vụ Bảo Tàng Thông Minh

Ứng dụng Web Dashboard chuyên nghiệp dành riêng cho **Nhân viên bảo tàng (Staff)**, **Kiểm duyệt viên (Curator)** và **Quản trị viên hệ thống (Administrator)** của dự án **Smart Museum Guide System (SMGS)**.

---

## 🛠 Công nghệ sử dụng
- **Core:** React 19 + Vite 8
- **UI & Thiết kế:** Vanilla CSS Design System phong cách Hoàng gia Di sản (Đỏ Bordeaux, Vàng Kim, Giấy Ngà, Kính mờ Glassmorphism)
- **Icons:** Lucide React
- **3D Viewer:** `@google/model-viewer` (Tương tác 3D WebGL / AR trực tiếp trên trình duyệt)

---

## 🏛 Các phân hệ chức năng theo vai trò

### 1. Quản trị viên (Administrator)
- **Tổng quan KPI:** Theo dõi lượt khách tham quan thời gian thực, lượt quét QR, doanh thu gói số.
- **Quản lý danh mục Bảo tàng & Không gian:** Phân cấp Bảo tàng → Tòa nhà → Tầng → Phòng/Khu trưng bày.
- **Quản lý Nhân sự & Phân quyền:** Phân bổ quyền hạn truy cập theo từng bảo tàng hoặc phòng trưng bày cụ thể.
- **Quản lý Gói dịch vụ & Giao dịch:** Thiết lập bảng giá Digital Pass, tra cứu giao dịch, đối soát và hoàn tiền.
- **Nhật ký Audit & Cài đặt API:** Lưu vết thay đổi dữ liệu, cấu hình API Key AI (Gemini 2.0 Flash) và Webhook thanh toán.

### 2. Nhân viên Bảo tàng (Museum Staff)
- **Quản lý Hiện vật & Mã QR:** Thêm mới/chỉnh sửa thông số hiện vật, niên đại, chất liệu, xuất file in mã QR chuẩn bảo tàng, gắn mô hình 3D AR.
- **AI Content Studio:**
  - *Thuyết minh Audio AI:* Sinh kịch bản thuyết minh theo độ tuổi (Thiếu nhi, Phổ thông, Học thuật).
  - *Quiz Generator AI:* Trích xuất tự động bộ 3-5 câu hỏi trắc nghiệm tương tác kèm giải thích.
  - *Dịch thuật Đa ngữ:* Bản dịch chuẩn tiếng Anh, Pháp, Nhật.
  - *Gửi hàng đợi kiểm duyệt 1-click.*
- **Lộ trình Tour & Triển lãm:** Thiết lập lộ trình các trạm dừng tham quan và sự kiện trưng bày chuyên đề.

### 3. Kiểm duyệt viên (Curator)
- **Hàng đợi Kiểm duyệt (Curation Queue):** Thẩm định kịch bản thuyết minh, câu hỏi quiz và tư liệu do nhân viên đệ trình.
- **So sánh phiên bản (Diff View):** So sánh trực quan giữa bản hiện tại và bản mới trước khi quyết định.
- **Phê duyệt / Từ chối / Yêu cầu hiệu chỉnh:** Quy trình kiểm duyệt chuẩn mực có lưu lý do và nhật ký.
- **Phản hồi Đánh giá của Khách:** Xem xếp hạng sao, ý kiến đóng góp và gửi câu trả lời chính thức từ Bảo tàng.

---

## 🚀 Hướng dẫn Chạy Ứng Dụng

### 1. Cài đặt thư viện
```bash
cd FrontEnd/smgs_web
npm install
```

### 2. Chạy môi trường phát triển (Dev server)
```bash
npm run dev
```
Trình duyệt sẽ mở tại `http://localhost:5173/`.

### 3. Đóng gói bản Production
```bash
npm run build
```
Thư mục xuất ra: `dist/`.
