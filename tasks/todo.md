# Task List: Đồng bộ Logic & API Backend mới sang Frontend (Web & Mobile)

## Checkpoint 1: Web Frontend Verified
- [x] Tất cả các trường lỗi thời trong Web đã được dọn sạch
- [x] Chạy `npm run build` trong `smgs_web` thành công

## Task 1: Cập nhật `CommerceManager.jsx` - Loại bỏ `validityStartsAt`, cố định `digital` và dọn validation
**Description:** Sửa form tạo và chỉnh sửa gói dịch vụ / tài nguyên trong `smgs_web/src/components/transactions/CommerceManager.jsx`:
- Loại bỏ trường `validityStartsAt: 'payment'` trong payload `body` gửi lên backend khi submit form.
- Đặt `form.kind` mặc định và cố định là `'digital'`. Xóa bỏ tùy chọn `admission` và `combo` khỏi dropdown (hoặc thay bằng trường hiển thị tĩnh `Nội dung số`).
- Xóa bỏ các điều kiện validate `hasAdmission`, `hasDigital`, `combo` cũ không còn phù hợp với ràng buộc backend mới.

**Acceptance criteria:**
- [x] Khi submit tạo gói dịch vụ mới, payload không chứa trường `validityStartsAt`.
- [x] Trường `kind` luôn gửi `'digital'`.
- [x] Không còn thông báo lỗi liên quan đến combo hay vé vào cửa khi lưu gói.

**Verification:**
- [x] Build thành công: `npm run build` trong `smgs_web` (0 errors)
- [x] Kiểm tra diff không sót trường thừa

**Dependencies:** None
**Files likely touched:**
- `smgs_web/src/components/transactions/CommerceManager.jsx`
**Estimated scope:** S (1 file)

---

## Task 2: Loại bỏ khối thao tác Thu hồi pass (`passes/{id}/revoke`) trong `CommerceManager.jsx`
**Description:** Backend đã xóa bỏ hoàn toàn endpoint `POST commerce/passes/{passId}/revoke`. Cần loại bỏ khối UI `<details><summary>Thu hồi quyền truy cập</summary>...</details>` cùng state `passId` trong component `ManagedOrder` của `CommerceManager.jsx` để tránh lỗi gọi API 404/405 không tồn tại.

**Acceptance criteria:**
- [x] Không còn đoạn mã gọi `commerce/passes/.../revoke` trong `ManagedOrder`.
- [x] Giao diện xem chi tiết đơn hàng gọn gàng, không hiển thị chức năng thu hồi thủ công đã bị deprecated.

**Verification:**
- [x] Build thành công: `npm run build` trong `smgs_web` (0 errors)

**Dependencies:** Task 1
**Files likely touched:**
- `smgs_web/src/components/transactions/CommerceManager.jsx`
**Estimated scope:** XS (1 file)

---

## Checkpoint 2: Mobile Frontend Verified
- [x] Luồng thanh toán ví 100% điều hướng thành công tức thì
- [x] Luồng thanh toán kết hợp hiển thị chi tiết số tiền trừ ví và mã VietQR chuẩn xác
- [x] Phân tích Dart không có lỗi cú pháp

## Task 3: Cập nhật `services_screen.dart` - Nhận diện thanh toán 100% bằng ví và điều hướng thành công tức thì
**Description:** Trong hàm `_submit()` của `_ServiceCheckoutScreenState` (`smgs_mobile/lib/screens/profile/services_screen.dart`):
- Nhận kết quả từ `commerce/orders/${order['id']}/payments/sepay`.
- Kiểm tra cờ `payment['paidFromWallet'] == true` hoặc `payment['status'] == 'succeeded'`.
- Nếu đơn hàng đã được thanh toán 100% từ ví: thực hiện rung haptic nhẹ và điều hướng trực tiếp sang `PaymentSuccessScreen` với trạng thái `paid`.
- Không điều hướng sang `VietQRPaymentScreen` khi đơn hàng không cần quét mã chuyển khoản.

**Acceptance criteria:**
- [x] Khi tài khoản có đủ số dư ví, sau khi bấm thanh toán, màn hình chuyển ngay sang `PaymentSuccessScreen`.
- [x] Không xuất hiện màn hình đếm ngược 15 phút với mã QR trống.

**Verification:**
- [x] Cú pháp Dart hợp lệ, không có lỗi phân tích.

**Dependencies:** None
**Files likely touched:**
- `smgs_mobile/lib/screens/profile/services_screen.dart`
**Estimated scope:** S (1 file)

---

## Task 4: Cập nhật `VietQRPaymentScreen` - Hiển thị minh bạch khấu trừ ví và số tiền VietQR
**Description:** Trong `VietQRPaymentScreen` (`smgs_mobile/lib/screens/profile/services_screen.dart`):
- Kiểm tra nếu đơn hàng có thanh toán một phần bằng ví (khi `order['amount'] > payment['amount']` và `payment['amount'] > 0`).
- Hiển thị khối tóm tắt tài chính nhỏ gọn, trang nhã:
  - Tổng giá trị đơn hàng.
  - Số dư ví đã khấu trừ.
  - Số tiền thực tế cần quét mã chuyển khoản VietQR.
- Đảm bảo mã QR và thông tin tài khoản hiển thị đúng số tiền `payment['amount']` cần thanh toán.

**Acceptance criteria:**
- [x] Người dùng thấy rõ ràng phần tiền đã được trừ từ ví và phần tiền còn lại cần quét QR.
- [x] Không làm xáo trộn bố cục thẻ VietQR và các nút Quick-Copy.

**Verification:**
- [x] Cú pháp Dart hợp lệ.

**Dependencies:** Task 3
**Files likely touched:**
- `smgs_mobile/lib/screens/profile/services_screen.dart`
**Estimated scope:** S (1 file)

---

## Task 5: Chuẩn hóa nhãn trạng thái thẻ tham quan (`services_screen.dart`)
**Description:** Tại mục danh sách thẻ tham quan trong `services_screen.dart`:
- Thay đổi nhãn trạng thái từ `'Đã hết hạn/Thu hồi'` thành `'Hết hiệu lực'` để phản ánh chính xác việc backend không còn hỗ trợ manual revoke mà chỉ đánh giá hiệu lực theo thời gian/lần sử dụng.

**Acceptance criteria:**
- [x] Nhãn trạng thái hiển thị chuẩn mực và nhất quán với quy tắc BE mới.

**Verification:**
- [x] Cú pháp Dart hợp lệ.

**Dependencies:** Task 4
**Files likely touched:**
- `smgs_mobile/lib/screens/profile/services_screen.dart`
**Estimated scope:** XS (1 file)
