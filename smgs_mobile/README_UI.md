# SMGS — Cẩm nang bảo tàng Việt

Bản trải nghiệm Flutter Web triển khai theo `SMGS_Main_Flow_Full_Spec.md` và [`SMGS_Tong_quan_de_tai.md`](SMGS_Tong_quan_de_tai.md). Khách tham quan dùng bố cục mobile; Nhân viên / Kiểm duyệt viên và Quản trị viên dùng dashboard web desktop. Giao diện và thông báo bằng tiếng Việt; phong cách giấy ngà, đỏ trầm, nâu và vàng cổ. Không cần trình giả lập.

Ma trận đối chiếu từng use case trong sơ đồ: [`USE_CASE_ALIGNMENT.md`](USE_CASE_ALIGNMENT.md).

## Chạy ứng dụng

```powershell
cd D:\SEP409\FrontEnd\smgs_mobile
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Mở http://localhost:8080, chọn một tài khoản mẫu rồi **Đăng nhập**. Hệ thống không có chế độ khách vãng lai.

Các tài khoản mẫu dùng chung mật khẩu `smgs123`:

- Khách tham quan: `khach@smgs.vn`
- Nhân viên / Kiểm duyệt viên: `curator@smgs.vn`
- Quản trị viên: `admin@smgs.vn`

Đây là thông tin mẫu được đóng gói cho bản thử nghiệm, không phải tài khoản thật. Đăng ký mới luôn tạo tài khoản khách tham quan trong bộ nhớ của phiên hiện tại. Hệ thống tự nhận diện vai trò từ tài khoản, không cho người dùng tự chọn quyền.

## Các luồng đã triển khai

| Luồng | Chức năng |
|---|---|
| MF-01 | Chọn bảo tàng, khám phá, quét mã mô phỏng, nhận diện có trạng thái xử lý/kết quả/không tìm thấy/thử lại, chi tiết hiện vật, hỏi đáp mẫu, đọc và điều khiển phát thuyết minh mô phỏng |
| MF-02 | Câu hỏi theo hiện vật, chọn/khóa đáp án, giải thích, kết quả, điểm, huy hiệu; lưu điểm tốt nhất để tránh cộng trùng |
| MF-03 | Chọn thời lượng và nhiều sở thích, lộ trình theo bảo tàng, sơ đồ minh họa, điểm hiện tại/tiếp theo, bỏ qua, kết thúc sớm và hoàn thành |
| MF-04 | Tìm kiếm không dấu, lọc chủ đề/bảo tàng/chuyên đề/phòng, sắp xếp tên bảo tàng, xóa bộ lọc, trạng thái rỗng |
| MF-05 | Lịch sử theo ngày và bảo tàng, chi tiết hiện vật/lượt thử tài/hành trình, góp ý có đánh giá bắt buộc và ngữ cảnh cụ thể |
| MF-06 | 4 dịch vụ số theo ngày, chọn bảo tàng/ngày/VNPay hoặc MoMo, mô phỏng thành công/thất bại/thử lại, quyền sử dụng theo ngày, danh sách đã đăng ký |
| MF-09 — khách tham quan | Màn hình mở đầu, đăng nhập bắt buộc, đăng ký, khôi phục mô phỏng, hồ sơ, huy hiệu, dịch vụ, cài đặt cỡ chữ/chuyển động, đăng xuất |
| MF-07 / MF-08 — nhân viên | Dashboard web nghiệp vụ, tổng quan nội dung, quản lý bảo tàng/hiện vật/phương tiện/bản đồ, tạo nội dung AI, kiểm duyệt, xuất bản và báo cáo |
| MF-09 — quản trị viên | Dashboard web quản trị, tổng quan hệ thống, người dùng, vai trò, bảo tàng, phân công, giao dịch, nhật ký và cài đặt |

Các thao tác nghiệp vụ của nhân viên và quản trị viên đang ở mức giao diện mô phỏng. Quy tắc duyệt, phiên bản nội dung, ma trận quyền, audit và API máy chủ cần được nối khi đặc tả backend được chốt.

## Trang chủ và chuyển động

Trang chủ có 7 chương nội dung: bảo tàng nổi bật, hiện vật, 3 chủ đề khám phá, hành trình 60 phút, điểm hẹn thứ hai, thử tài và cẩm nang mở rộng; thêm hiện vật vừa xem khi có lịch sử.

Ảnh dịch chuyển theo cuộn, nội dung hiện dần một lần, dấu hoa văn xoay và thanh tiến độ trên đầu trang cố định. Có nút về đầu trang. Chuyển động tắt khi người dùng chọn giảm chuyển động hoặc thiết bị bật tùy chọn này. Hỗ trợ đọc màn hình trên web không tự tắt hiệu ứng.

## Phạm vi mô phỏng

- Tài khoản, lịch sử, mục đã lưu, góp ý, điểm, huy hiệu và dịch vụ được giữ trong bộ nhớ. Tải lại trang đặt lại dữ liệu; đăng xuất xóa dữ liệu trải nghiệm của phiên đăng nhập.
- Nhận diện và quét mã không truy cập máy ảnh. Có nhánh không tìm thấy để thử luồng lỗi.
- Hỏi đáp trả lời từ nội dung mẫu; câu hỏi ngoài phạm vi có phản hồi rõ ràng. Giọng nói là phần giới thiệu chức năng chưa kết nối.
- Thanh thuyết minh mô phỏng phát/tạm dừng/tiến độ, **không phát âm thanh**.
- Bản đồ chỉ minh họa lộ trình; không có GPS, đo khoảng cách hay định vị trong nhà.
- Giá dịch vụ là giá minh họa. Thanh toán **không thu tiền, không kết nối VNPay/MoMo**. Chỉ kết quả thành công mới ghi nhận quyền sử dụng mẫu; không đăng ký trùng cùng dịch vụ/bảo tàng/ngày.
- Không gửi thư khôi phục hay gửi góp ý ra ngoài ứng dụng.

## Cấu trúc để tích hợp tiếp

- `lib/services/app_services.dart`: hợp đồng dịch vụ và triển khai mẫu cho tài khoản, bộ sưu tập, nhận diện, hỏi đáp, câu hỏi, hành trình, thanh toán và danh mục dịch vụ.
- `lib/models/experience.dart`: người dùng, câu hỏi/kết quả, lịch sử, hành trình, góp ý, dịch vụ/đăng ký.
- `lib/data/visit_store.dart`: trạng thái trải nghiệm dùng chung qua ChangeNotifier.
- `lib/services/app_preferences.dart`: cỡ chữ và lựa chọn chuyển động.
- `lib/screens/`: các màn hình và điều hướng cho khách tham quan.
- `test/main_flows_test.dart`: nhánh chính/nhánh lỗi của các luồng mới; các tệp kiểm thử còn lại kiểm tra trang chủ, chuyển động, tìm kiếm, câu hỏi và bố cục.

Khi nối hệ thống thật, thay triển khai dịch vụ và lớp lưu trữ, bổ sung xác thực phía máy chủ, dữ liệu bảo tàng thực, xử lý lỗi mạng, quyền truy cập và thanh toán phía máy chủ. Các trạng thái mẫu ở đây không thay cho kiểm tra quyền hoặc giao dịch thật.

## Kịch bản trình diễn

1. Đăng nhập bằng tài khoản mẫu.
2. Chọn bảo tàng → Khám phá hiện vật → Quét mã mô phỏng.
3. Mở hiện vật → Hỏi hướng dẫn viên → chọn câu hỏi gợi ý.
4. Quay lại hiện vật → Thử tài → trả lời → xem điểm và huy hiệu.
5. Về bảo tàng → Hành trình dành cho bạn → chọn sở thích → bắt đầu.
6. Thử bỏ qua một điểm hoặc hoàn thành; mở Cá nhân → Lịch sử khám phá → chi tiết → góp ý.
7. Mở Dịch vụ số → Chọn dịch vụ → chọn ngày và phương thức → chọn kết quả mô phỏng → xác nhận.
8. Thử nhánh thất bại rồi thử lại thành công; mở Dịch vụ đã đăng ký.

## Kiểm tra và đóng gói

```powershell
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

Ảnh đóng gói và nguồn: `assets/images/SOURCES.md`. Noto Serif / Noto Sans kèm giấy phép OFL trong `assets/fonts`.
