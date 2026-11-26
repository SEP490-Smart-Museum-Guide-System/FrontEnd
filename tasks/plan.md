# Implementation Plan: Đồng bộ Logic & API Backend mới sang Frontend (Web & Mobile)

## Overview
Dự án Backend (`Smart_Museum_Guide_System`) đã có những cập nhật quan trọng về quy tắc nghiệp vụ (Business Rules) và hợp đồng dữ liệu (API Contracts) trong cụm chức năng Commerce, Ví và Thanh toán SePay:
1. **Cấu hình gói dịch vụ**: Rút gọn chỉ hỗ trợ hình thức nội dung số (`digital`), loại bỏ các loại `admission` và `combo`; bỏ trường `validityStartsAt` trong DTO tạo gói; bỏ endpoint thủ công thu hồi vé `passes/{passId}/revoke`.
2. **Cơ chế thanh toán SePay & Ví**: Hỗ trợ cơ chế thanh toán lai (Hybrid Payment). Nếu tài khoản có số dư ví, hệ thống sẽ tự động trừ ví trước:
   - Nếu ví đủ trả 100%: Hoàn tất đơn hàng ngay (`paidFromWallet: true`, `status: 'succeeded'`), không cần quét VietQR.
   - Nếu ví trả một phần: Trừ ví phần có sẵn, chỉ tạo mã VietQR cho số tiền còn lại (`amountDue`).

Kế hoạch này phân rã các đầu việc cụ thể để loại bỏ mã nguồn cũ, dọn dẹp các trường lỗi thời và tối ưu trải nghiệm người dùng trên cả Web quản trị (`smgs_web`) và Ứng dụng di động (`smgs_mobile`).

---

## Architecture & Code Changes

### 1. Web Frontend (`smgs_web`)
- **File**: `smgs_web/src/components/transactions/CommerceManager.jsx`
- **Thay đổi**:
  - Cố định `kind` là `'digital'`, ẩn/loại bỏ dropdown chọn `admission`/`combo`.
  - Loại bỏ hoàn toàn trường `validityStartsAt: 'payment'` khi gửi payload tạo/sửa gói dịch vụ lên `POST/PUT commerce/museums/{id}/products`.
  - Loại bỏ logic kiểm tra chéo phức tạp `hasAdmission`, `hasDigital`, `combo` trong form validation.
  - Xóa bỏ block UI và handler gọi `backend('commerce/passes/${passId}/revoke', { method: 'POST' })` trong modal chi tiết đơn hàng (`ManagedOrder`).

### 2. Mobile Frontend (`smgs_mobile`)
- **File**: `smgs_mobile/lib/screens/profile/services_screen.dart`
- **Thay đổi**:
  - Tại `_submit()`: Đón nhận kết quả từ `commerce/orders/{id}/payments/sepay`. Nếu `payment['paidFromWallet'] == true` hoặc `payment['status'] == 'succeeded'`, điều hướng trực tiếp sang `PaymentSuccessScreen` với rung phản hồi haptic, không mở màn hình QR rỗng.
  - Tại `VietQRPaymentScreen`: Hiển thị rõ ràng breakdown thanh toán (Tổng đơn hàng, Khấu trừ ví, Số tiền chuyển khoản VietQR) nếu có cấn trừ ví trước đó.
  - Tại danh sách vé/pass: Cập nhật nhãn trạng thái từ `'Đã hết hạn/Thu hồi'` thành `'Hết hiệu lực'`.

---

## Task List

### Phase 1: Web Frontend Cleanup (`smgs_web`)
- [ ] Task 1: Cập nhật `CommerceManager.jsx` - Loại bỏ `validityStartsAt`, cố định `digital`, dọn dẹp validation cũ.
- [ ] Task 2: Loại bỏ khối thao tác Thu hồi pass (`passes/{id}/revoke`) trong `CommerceManager.jsx`.

### Checkpoint 1: Web Frontend Verified
- [ ] Chạy `npm run build` trong `smgs_web` không phát sinh lỗi biên dịch.

### Phase 2: Mobile Frontend Alignment (`smgs_mobile`)
- [ ] Task 3: Cập nhật `services_screen.dart` - Nhận diện thanh toán 100% bằng ví và điều hướng thành công tức thì.
- [ ] Task 4: Cập nhật `VietQRPaymentScreen` - Hiển thị minh bạch số tiền khấu trừ ví và số tiền còn lại cần quét mã VietQR.
- [ ] Task 5: Chuẩn hóa nhãn trạng thái vé trong danh sách vé đã mua (`services_screen.dart`).

### Checkpoint 2: Mobile Frontend Verified
- [ ] Chạy phân tích cú pháp Dart / Flutter không có lỗi linter/compiler.

---

## Risks and Mitigations
| Nguy cơ | Tác động | Giải pháp |
|---------|----------|-----------|
| Người dùng ấn thanh toán khi ví đủ 100% tiền bị kẹt ở màn hình QR 0đ | Cao | Bắt cờ `paidFromWallet` và `status == 'succeeded'` ngay tại hàm callback gọi API, chuyển ngay sang `PaymentSuccessScreen`. |
| Quản lý trên Web tạo gói mới bị BE trả về 400 Bad Request | Cao | Loại bỏ trường thừa `validityStartsAt` và đảm bảo `kind: 'digital'` tuyệt đối. |
