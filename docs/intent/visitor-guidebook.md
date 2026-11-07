# Statement of Intent: Sổ tay hướng dẫn & Cẩm nang Khách tham quan
**Dự án:** Smart Museum Guide System (SMGS)  
**Thời gian xác lập:** 07/11/2026  
**Trạng thái:** Đã phê duyệt (Confirmed)

---

## 1. Mục tiêu (Outcome)
Xây dựng trải nghiệm dẫn dắt 2 tầng chuẩn mực di sản dành cho Khách tham quan (Visitor):
1. **Tầng 1 — Onboarding Walkthrough (Modal chào mừng 3 bước):** 
   - Tự động bật lên khi khách tham quan lần đầu mở ứng dụng hoặc đăng nhập.
   - Giới thiệu 3 năng lực cốt lõi: 
     - *Bước 1:* Quét mã QR hoặc Chụp ảnh AI Vision tại tủ trưng bày hiện vật.
     - *Bước 2:* Lắng nghe Thuyết minh âm thanh AI TTS tiếng Việt đa giọng điệu.
     - *Bước 3:* Xem vị trí và chỉ đường tự động trên Sơ đồ tầng bảo tàng (thuật toán Dijkstra).
   - Có cơ chế lưu cờ `hasSeenOnboarding` trong Local Storage / SharedPreferences để không làm phiền ở các lần truy cập tiếp theo.
2. **Tầng 2 — Heritage Handbook Hub (Cẩm nang tham quan cố định):**
   - Biểu tượng hoặc nút bấm cố định "Cẩm nang tham quan" tại Trang chủ / thanh Header.
   - Cho phép khách mở lại bất cứ lúc nào để xem:
     - Hướng dẫn nhanh cách sử dụng các tính năng công nghệ.
     - Quy tắc ứng xử và văn hóa tham quan bảo tàng (giữ trật tự, không chạm hiện vật, quy định chụp ảnh).
     - Sơ đồ tiện ích: Vị trí phòng vệ sinh, quầy gửi đồ, lối thoát hiểm, hỗ trợ xe lăn.

---

## 2. Đối tượng thụ hưởng (Target User)
* **Khách tham quan mới (First-time Visitors):** Khách lần đầu vào trải nghiệm di sản trên Web Visitor (`/visitor/`) hoặc ứng dụng di động Flutter.
* **Khách tham quan định kỳ (Returning Visitors):** Cần tra cứu nhanh tiện ích hoặc quy định bảo tàng thông qua Cẩm nang cố định.

---

## 3. Lý do thực hiện (Why now)
Khách tham quan bảo tàng có nhiều lứa tuổi và mức độ tiếp cận công nghệ khác nhau. Việc phối hợp giữa AI Vision, AI TTS và Sơ đồ Dijkstra rất hiện đại nhưng dễ gây bỡ ngỡ nếu không có điểm chạm hướng dẫn tinh tế, sang trọng ngay trong 15 giây đầu tiên.

---

## 4. Tiêu chuẩn thành công (Success Metrics & Design Bar)
* **Ngôn ngữ thiết kế Heritage Editorial (Anti-slop):**
  - Màu chủ đạo: Đỏ Rượu Vang Burgundy (`#800020`), Vàng kim Muted Gold (`#C5A059`), nền giấy Antique Ivory/Kem ấm (`#FAF7F2`).
  - Typography: Serif thanh lịch (Noto Serif / Playfair), khoảng cách thoáng đãng, phân cấp thị giác rõ ràng.
* **Hiệu năng & Tinh gọn:** 
  - Đọc lướt và hoàn thành trong dưới 15 giây.
  - Chuyển slide mượt mà, hỗ trợ cả nút "Tiếp tục" và "Bỏ qua".
  - Không gây giật lag, không chèn video dung lượng lớn làm chậm ứng dụng.

---

## 5. Ràng buộc (Constraints)
* Không làm gián đoạn luồng tham quan của người dùng đã có kinh nghiệm (kiểm tra trạng thái đã xem).
* Đồng bộ 100% với hệ thống Design System hiện tại của `smgs_mobile` và `smgs_web`.

---

## 6. Phạm vi loại trừ (Out of Scope)
* Không tích hợp video streaming nặng tốn băng thông 4G của khách.
* Không ảnh hưởng tới luồng làm việc của các vai trò nội bộ (`Staff`, `Curator`, `Admin`).
