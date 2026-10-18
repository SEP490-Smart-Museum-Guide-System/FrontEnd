# BÁO CÁO TỔNG KẾT HOÀN THIỆN GIAO DIỆN MOBILE (SMGS VISITOR)
## (Mobile UI/UX Implementation & Heritage Taste Refinement Summary)

> **Dự án:** Smart Museum Guide System (SMGS) — Mobile Flutter  
> **Vai trò:** Khách tham quan (Visitor)  
> **Phong cách thẩm mỹ:** **Hoàng gia Di sản (Royal Heritage & Silk Ivory)**  
> **Ngày hoàn thành:** 17/10/2026  
> **Trạng thái kiểm thử:** 27/27 unit & widget tests passed, `flutter analyze` 0 issues.

---

## 1. NGUYÊN TẮC THIẾT KẾ VÀ TASTE SKILLS ÁP DỤNG

Tuân theo lựa chọn định hướng thiết kế **Hoàng gia Di sản (Royal Heritage & Silk Ivory)** được người dùng phê duyệt, toàn bộ hệ thống giao diện `smgs_mobile` được hoàn thiện với các quy chuẩn thị giác cao cấp:

- **Bảng màu di sản (Heritage Color Palette):**
  - **Nền lụa ngà cổ (`AppColors.antiqueIvory` - `#F4EBDD`):** Tạo cảm giác giấy dó / lụa tơ tằm truyền thống, dịu mắt và tôn vinh hiện vật.
  - **Đỏ huyết dụ sơn son (`AppColors.deepBurgundy` - `#6B2E2E`):** Màu sắc chủ đạo của cung đình Việt, mang lại sự trang trọng, uy nghiêm và lịch sử.
  - **Vàng đồng hoàng gia (`AppColors.mutedGold` - `#B38B59`):** Dùng làm viền thẻ vàng son (Gold Panel), huy hiệu vinh danh, ngôi sao thành tích.
  - **Nâu gỗ mun trầm (`AppColors.darkBrown` - `#3B302A`):** Màu chữ chính tương phản cao, mô phỏng mực nho trên giấy cổ.
- **Tính toán bố cục chống tràn (Responsive & Anti-Overflow):**
  - Toàn bộ các dòng chữ và nút bấm hành động đều được bọc trong các `Expanded` và `Flexible` widget, đảm bảo tương thích từ màn hình nhỏ hẹp 300px/320px đến các kích thước màn hình lớn mà không xảy ra lỗi RenderFlex overflow.

---

## 2. CÁC MÀN HÌNH VÀ TÍNH NĂNG MỚI ĐÃ HOÀN THIỆN

### 2.1. Màn hình Quiz Tích lũy Trong Ngày (`DailyQuizScreen`)
- **Tập tin:** `lib/screens/artifact/daily_quiz_screen.dart`
- **Mã màn hình:** `MOB-V11`
- **Nghiệp vụ đáp ứng (Quyết định [U2]):**
  - Khách tham quan không bị bắt buộc phải làm trắc nghiệm ngay tại tủ trưng bày. Tất cả hiện vật đã quét mã QR hoặc nhận diện AI thành công trong ngày sẽ tự động được tích lũy vào danh sách này.
  - Khách có thể thong thả mở lại app vào buổi tối tại nhà/khách sạn để làm bài kiểm tra nhận điểm thưởng và mở khóa huy hiệu.
- **Thành phần giao diện:**
  - Panel tóm tắt tiến độ mạ vàng: Bộ đếm số hiện vật mở quiz trong ngày, số bài chưa làm, số bài đã hoàn thành.
  - Bộ lọc 3 trạng thái: [Tất cả] | [Chưa làm] | [Đã hoàn thành].
  - Thẻ hiện vật di sản: Ảnh minh họa hiện vật nét cao, tên hiện vật, niên đại, phòng trưng bày, phần thưởng (+20 điểm), nút [Làm bài ngay] hoặc kết quả bài làm kèm tùy chọn [Làm lại câu đố khác].
  - Trạng thái trống (Empty State) trang nhã khi chưa quét hiện vật nào.

---

### 2.2. Màn hình Chỉ đường Trong Bảo tàng tới Hiện vật Kế tiếp (`IndoorGuidanceScreen`)
- **Tập tin:** `lib/screens/museum/indoor_guidance_screen.dart`
- **Mã màn hình:** `MOB-V07`
- **Nghiệp vụ đáp ứng (Quyết định [U2]):**
  - Hệ thống chỉ đường từ **vị trí hiện vật xác định gần nhất** tới hiện vật tiếp theo trong lộ trình.
  - Không cần theo dõi vị trí GPS/Bluetooth liên tục trong nhà; vị trí sẽ được cập nhật lại khi khách quét mã QR hoặc nhận diện ảnh tại điểm dừng tiếp theo.
- **Thành phần giao diện:**
  - Thẻ đối chiếu hành trình: Thể hiện rõ Điểm xuất phát (Tên & phòng hiện vật hiện tại) → Điểm đến (Tên & phòng hiện vật kế tiếp).
  - Sơ đồ định vị tĩnh (Custom Canvas Blueprint Painter): Mô phỏng sơ đồ mặt bằng các phòng trưng bày và đường nối lộ trình di chuyển.
  - Hướng dẫn chỉ đường từng bước (Step-by-step guidance): Chỉ rõ phương hướng rẽ, khoảng cách ước tính (mét) và vị trí đặt tủ kính hiện vật.
  - Nút hành động nhanh: [Đã tới nơi · Quét mã QR hiện vật này] để mở máy ảnh quét ngay tại chỗ.

---

### 2.3. Khối Tương tác Quyết định Sau khi Đọc Hiện vật (Post-Reading Decision Panel)
- **Tập tin:** `lib/screens/artifact/artifact_detail_screen.dart`
- **Mã màn hình:** `MOB-V04`
- **Nghiệp vụ đáp ứng (Quyết định [U2]):**
  - Sau khi khách cuộn xuống đọc xong câu chuyện hiện vật, hệ thống hiển thị ngay một Khối tương tác trang trọng:
    - **Lựa chọn 1:** [Làm Quiz ngay (+20 điểm)] → Mở trực tiếp bài trắc nghiệm 2 câu.
    - **Lựa chọn 2:** [Để khi rảnh làm sau (Tích lũy cuối ngày)] → Lưu vào danh sách `DailyQuizScreen` và xuất thông báo xác nhận dịu nhẹ.
    - **Lựa chọn 3:** [Chỉ đường tới: {Tên hiện vật tiếp theo}] → Mở màn hình dẫn đường trong nhà.

---

### 2.4. Trung tâm Hỗ trợ & Yêu cầu Hoàn tiền (`SupportRefundScreen`)
- **Tập tin:** `lib/screens/profile/support_refund_screen.dart`
- **Mã màn hình:** `MOB-V15`
- **Nghiệp vụ đáp ứng (Bối cảnh [Q22], [QB]):**
  - Cung cấp kênh chính thức để Visitor gửi khiếu nại và yêu cầu hoàn tiền dịch vụ (Vé vào cổng, Dịch vụ số, Combo) khi gặp sự cố khách quan (bảo tàng đóng cửa, lỗi đường truyền, mua nhầm ngày).
  - Yêu cầu này sẽ được chuyển trực tiếp tới phân hệ xử lý của **System Staff** trên cổng Web.
- **Thành phần giao diện:**
  - Panel giải thích chính sách bảo vệ khách hàng và các mức tỷ lệ hoàn tiền quy định (100%, 80%, 50%).
  - Form gửi yêu cầu hoàn tiền: Chọn loại khiếu nại, chọn đơn hàng liên quan, chọn lý do cụ thể, chọn tỷ lệ hoàn tiền đề xuất, ô nhập mô tả chi tiết.
  - Lịch sử theo dõi các ticket đã gửi: Thể hiện mã ticket (TCK-XXXX), trạng thái xử lý ([Đang tiếp nhận], [Đã phê duyệt]), lý do và tỷ lệ hoàn tiền.

---

### 2.5. Tối ưu Phản hồi Quét & Nhận diện Hiện vật (`QRScanScreen`)
- **Tập tin:** `lib/screens/artifact/qr_scan_screen.dart`
- **Mã màn hình:** `MOB-V03`
- **Nghiệp vụ đáp ứng:**
  - Khi quét mã QR hoặc chụp ảnh AI nhận diện thành công:
    - Lập tức hiển thị huy hiệu xác nhận: *“Vị trí của bạn đã được cập nhật tại: {Phòng/Khu}”*.
    - Thông báo xác nhận: *“Câu đố hiện vật đã được thêm vào Danh sách Quiz trong ngày!”*.
    - Nút bấm xem câu chuyện hiện vật nổi bật.

---

### 2.6. Tích hợp Điều hướng tại Màn hình Hồ sơ Cá nhân (`ProfileScreen`)
- **Tập tin:** `lib/screens/profile/profile_screen.dart`
- **Thành phần cập nhật:**
  - Bổ sung ActionTile dẫn trực tiếp vào **Quiz tích lũy trong ngày** kèm chỉ số số lượng hiện vật đã mở trong phiên.
  - Bổ sung ActionTile dẫn vào **Hỗ trợ & Yêu cầu hoàn tiền** để khách dễ dàng tiếp cận quyền lợi người dùng.

---

### 2.7. Nâng cấp Kho Trạng thái Dữ liệu (`VisitStore` & Data Models)
- **Tập tin:** `lib/data/visit_store.dart` và `lib/models/experience.dart`
- **Nội dung bổ sung:**
  - Bổ sung `SupportTicket` model đại diện cho khiếu nại và hoàn tiền.
  - Cập nhật enum `UserRole` đầy đủ 5 vai trò (bao gồm `curator`).
  - Quản trị danh sách `todayScannedArtifactIds` cho phiên tham quan trong ngày.
  - Quản trị danh sách các hiện vật hoãn quiz `deferredQuizArtifactIds`.
  - Hàm tìm kiếm hiện vật kế tiếp thông minh `getNextArtifact(Artifact current)` phục vụ dẫn đường liên tục giữa các phòng.

---

## 3. KẾT QUẢ KIỂM THỬ VÀ ĐẢM BẢO CHẤT LƯỢNG

Toàn bộ các thay đổi đều được kiểm thử tự động nghiêm ngặt bằng công cụ của Flutter SDK:

1. **Kiểm tra phân tích tĩnh (`flutter analyze`):**
   - **Kết quả:** `No issues found!` (0 lỗi, 0 cảnh báo, loại bỏ hoàn toàn các warning và member deprecated).
2. **Kiểm thử giao diện & luồng người dùng (`flutter test`):**
   - **Kết quả:** **27/27 bài test chạy thành công 100%**, bao gồm:
     - `widget_test.dart`: Kiểm tra bố cục tiếng Việt và 5 Tab điều hướng.
     - `home_test.dart`: Kiểm tra các chương nội dung, thẻ hành trình và hướng dẫn tham quan.
     - `motion_test.dart`: Kiểm tra hiệu ứng chuyển cảnh mượt mà giữa các trang.
     - `main_flows_test.dart`: Kiểm tra toàn bộ luồng đăng nhập, quét QR/nhận diện ảnh, thuyết minh đa phiên bản, mô hình 3D, mua vé/combo, lưu feedback và chống trùng lặp điểm/huy hiệu.
