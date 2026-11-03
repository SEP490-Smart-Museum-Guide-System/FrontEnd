# FE sử dụng dữ liệu Backend — 03/11/2026

## Nguyên tắc

- Dữ liệu nghiệp vụ trên React và Flutter lấy qua API; FE không truy cập DB trực tiếp.
- Danh sách rỗng từ API được giữ rỗng. Lỗi mạng, hết quyền hoặc phản hồi sai định dạng phải hiển thị lỗi; không thay bằng bảo tàng, người dùng, đơn hàng hay tour mẫu.
- Chỉ giữ hiện vật phục vụ trải nghiệm AI/3D và dữ liệu kiểm thử trong thư mục `test`/`tests`. Fixture kiểm thử không được import vào ứng dụng.
- Không xóa bản ghi trong DB, không thay đổi BE và không triển khai production trong đợt này. Nếu API trả về dữ liệu seed của BE, FE vẫn hiển thị đúng dữ liệu đó.

## Dữ liệu và thao tác đã rà soát

| Nhóm | Nguồn dữ liệu / hành vi |
| --- | --- |
| Đăng nhập | API xác thực, vai trò từ phiên BE; không có tài khoản giả tự đăng nhập thành công |
| Bảo tàng, hiện vật | API danh sách và chi tiết; không tự điền ảnh Ngọc Lũ, tọa độ Hà Nội, giờ mở cửa hay mã QR thử nghiệm |
| Phòng trưng bày | `museums/{id}/indoor-structure` và `museums/{id}/galleries`; không dùng cây tòa nhà/phòng mẫu |
| Nội dung, Giám tuyển | Phiên bản nội dung, hàng đợi và thao tác kiểm duyệt qua API |
| Người dùng | `admin/accounts`; tạo/cập nhật chỉ báo thành công sau khi BE phản hồi |
| Tour | Tour và thứ tự hiện vật từ BE; sơ đồ giả đã đổi thành danh sách điểm dừng |
| Gói dịch vụ, đơn mua | API commerce; tạo đơn và yêu cầu thanh toán không đồng nghĩa thanh toán thành công |
| Quyền premium | `commerce/passes/me`; không còn hàm kích hoạt giao dịch giả trong VisitStore |
| Lượt tham quan | `visits/me`, `visits/{id}`, tạo và hoàn tất qua API |
| Feedback, hỗ trợ | `feedbacks`, `complaints`; không lưu thành công giả trong bộ nhớ |
| Quiz tài khoản | Danh sách quiz hằng ngày, lượt làm và kết quả do BE cấp |
| Điểm, huy hiệu | API gamification; điểm quiz mẫu không được trình bày như điểm tài khoản |
| Bản đồ | Dùng sơ đồ đã lưu/xuất bản; không tự tạo mặt bằng, rẽ phải hoặc khoảng cách 15–20 mét |

Các API dạng mảng được đọc một lần; API có phân trang được đọc theo metadata. Đã sửa lỗi danh sách đúng 50 bản ghi có thể bị đọc lặp. Cache theo tài khoản và phạm vi bảo tàng được xóa khi đổi phiên/phạm vi; phản hồi tìm kiếm cũ không được ghi đè truy vấn mới.

## Những dữ liệu mẫu được giữ theo yêu cầu

- `smgs_web/src/data/aiDemoArtifacts.js`: ví dụ hiện vật trong Xưởng AI, gắn nhãn mẫu. ID mẫu không được gửi thành bản ghi nghiệp vụ.
- `smgs_mobile/lib/data/mock/mock_artifacts.dart`: hiện vật cho phần **Trải nghiệm AI / 3D mẫu**, quiz và nhận diện mẫu.
- Mô hình GLB và ảnh minh họa đi kèm các hiện vật mẫu. Hiện vật số `1` trong DB **không** được coi là hiện vật mẫu `artifact_1`.
- Các fake service và dữ liệu bảo tàng trong `smgs_mobile/test/support` chỉ phục vụ kiểm thử.

Ảnh thiếu/lỗi dùng khung chờ trung tính. Không lấy ảnh của bảo tàng hoặc hiện vật khác để thay thế. Mô hình 3D của hiện vật thật chỉ mở khi có URL tương ứng.

## Trạng thái cục bộ còn lại

Hiện vật vừa mở, bookmark, tiến độ xem tour trong phiên và kết quả quiz mẫu vẫn là trạng thái tương tác cục bộ, được ghi rõ trên UI. Chúng không phải lịch sử tham quan, giao dịch hoặc điểm tài khoản do BE xác nhận; đăng xuất sẽ xóa trạng thái phiên.

## Phần còn phụ thuộc Backend

- Chưa có API hoàn tiền/nhật ký hệ thống trong phạm vi BE đã đối chiếu: FE hiển thị chưa hỗ trợ, không tính số tiền hoàn hoặc sinh audit giả.
- API commerce hiện giới hạn Admin/Museum Staff; System Staff chưa có quyền đối soát tương ứng.
- Chưa có danh sách triển lãm chuyên đề và bộ thống kê đầy đủ: không hiển thị số lượt quét/đánh giá giả.
- Quyền hiển thị bản đồ độc lập chưa có trường BE tương ứng; danh sách công khai theo trạng thái hoạt động của bảo tàng.
- Chưa có API Visitor liệt kê sơ đồ trong nhà theo bảo tàng. Không dùng `museumId` thay `mapId`, không tạo đường đi tưởng tượng. Luồng bản đồ đã có ID xuất bản vẫn giữ nguyên.
- Form hiện vật chỉ lưu các trường API hỗ trợ. Media, nội dung kiểm duyệt và vị trí bản đồ được quản lý ở các màn tương ứng.

## Kiểm tra và cập nhật bản web

```powershell
cd D:\SEP409\FrontEnd\smgs_web
npm test
npm run build
npm run lint

cd D:\SEP409\FrontEnd\smgs_mobile
flutter test --no-pub
flutter analyze --no-pub

cd D:\SEP409\FrontEnd
.\tools\update-visitor-web.ps1 -Flutter C:\dev\flutter\bin\flutter.bat
cd smgs_web
npm run build
```

Vercel hiện chỉ build React và đóng gói thư mục `smgs_web/public/visitor` đã có trong repo. Vì vậy phải cập nhật bundle Flutter này trước khi đưa thay đổi Visitor lên Vercel; chỉ sửa Dart rồi build React sẽ vẫn phục vụ Visitor cũ.

Kết quả kiểm tra tại máy: React 15 ca đạt, Flutter 52 ca đạt; mỗi bộ có 1 ca xác thực live bị bỏ qua do chưa cấu hình môi trường. `flutter analyze` không có vấn đề; React và Flutter web build thành công. React lint không có lỗi chặn nhưng còn cảnh báo tồn tại trong các component; bundle React vẫn có cảnh báo kích thước.

Kiểm thử HTTP dùng phản hồi giả lập trong thư mục test để xác minh DB trống, lỗi API, phân trang, giữ mã đơn khi thanh toán lỗi, không báo gửi feedback thành công khi BE từ chối và không gán mô hình mẫu cho ID thật. Đây không phải bằng chứng đã kiểm thử end-to-end với DB production. Hai ca xác thực live của React/Flutter được bỏ qua khi chưa có cấu hình tài khoản kiểm thử.

Sau khi chạy BE và đăng nhập tài khoản thật, kiểm tra thêm: tạo một bảo tàng/hiện vật ở môi trường thử, tải lại trang để xác nhận dữ liệu tồn tại, đổi bảo tàng/đăng xuất để kiểm tra phạm vi, ngắt BE để xem trạng thái lỗi. Chưa thực hiện thao tác ghi trên DB thật trong lần rà soát này.
