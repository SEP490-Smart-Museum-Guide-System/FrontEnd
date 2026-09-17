# Giao diện SMGS bằng tiếng Việt

Ứng dụng Flutter ưu tiên trình duyệt web, theo phong cách cẩm nang bảo tàng. Bảng màu gồm ngà, đỏ trầm, nâu và vàng nhạt. Phông Noto Serif / Noto Sans hỗ trợ tiếng Việt, đi kèm giấy phép OFL trong assets/fonts. Ảnh thật được tối ưu và đóng gói trong ứng dụng; xem nguồn và giấy phép trong assets/images/SOURCES.md. Họa tiết giấy, dấu tròn và minh họa được vẽ trực tiếp bằng Flutter.

## Chạy trên web

```powershell
cd D:\SEP409\FrontEnd\smgs_mobile
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Mở http://localhost:8080 trong trình duyệt. Không cần trình giả lập.

## Kiểm tra

```
flutter analyze
flutter test
flutter build web
```

## Phạm vi

- Trang chủ gồm 7 chương: bảo tàng nổi bật, câu chuyện hiện vật, 3 chủ đề có bộ lọc, hành trình 60 phút, điểm đến thứ hai, thử tài và cẩm nang dạng mở rộng. Hiện vật vừa xem xuất hiện thêm ở cuối trang.
- Hiệu ứng cuộn: ảnh dịch chuyển theo cuộn, các khối nội dung hiện dần một lần, thanh đầu trang cố định có dấu hoa văn xoay và tiến độ đọc. Ảnh nối liền từ thẻ sang chi tiết; tiêu đề chi tiết thu gọn khi cuộn. Có nút về đầu trang.
- Tôn trọng tùy chọn giảm chuyển động của thiết bị. Bật hỗ trợ đọc màn hình trên web không tự tắt hiệu ứng; chỉ `disableAnimations` mới giảm chuyển động.

- Các trang: trang chủ, tìm kiếm/lọc bảo tàng và hiện vật, chi tiết, khám phá, xem trước quét mã/nhận diện ảnh, hỏi đáp, thử tài/kết quả, thiết lập/lộ trình/hành trình, cá nhân, lịch sử, đã lưu, góp ý và dịch vụ số.
- Tìm kiếm chấp nhận tiếng Việt có dấu hoặc không dấu.
- Lịch sử, đánh dấu, kết quả câu hỏi và số hành trình được lưu trong phiên; tải lại sẽ đặt lại.
- Bộ sưu tập là dữ liệu minh họa; giờ mở cửa chỉ để tham khảo.
- Máy ảnh/nhận diện, trợ lý trực tuyến, âm thanh, đăng nhập, gửi góp ý và thanh toán chưa có dịch vụ nền. Giao diện nêu rõ trạng thái; không mô phỏng giao dịch thành công hoặc phát âm thanh giả.
- Chỉ có ngôn ngữ tiếng Việt, bao gồm các nhãn hệ thống của Flutter.
