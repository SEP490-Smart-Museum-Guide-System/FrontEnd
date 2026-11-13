# Tối giản UI và thư viện ảnh hiện vật — 13/11/2026

## Giao diện web cho bốn vai trò nghiệp vụ
- Dùng chung màu nền, khoảng cách, nút và thông báo; chia điều hướng theo nhóm công việc.
- Các thao tác phụ của hiện vật/bảo tàng/tài khoản được gom vào menu thao tác; các mục dịch vụ dùng thanh tab.
- Thông báo xuất hiện ở phía trên, có nút đóng và thời gian đọc; lỗi thao tác được thông báo bên cạnh lỗi trong biểu mẫu.
- Xử lý khiếu nại không còn báo thành công trước khi máy chủ trả kết quả.

## Upload và ảnh Visitor
- Upload nhiều ảnh tuần tự, báo số ảnh đã lưu; ảnh lỗi được giữ để thử lại. Không gửi lại ảnh thành công khi thử lại.
- Nếu thông tin hiện vật đã tạo nhưng upload ảnh bị lỗi, giữ ID hiện vật để lần thử lại cập nhật bản ghi đó.
- Mobile đọc toàn bộ media image, sắp theo sortOrder, bỏ URL trùng, tải lại chi tiết khi mở hiện vật.
- Vuốt hoặc bấm mũi tên để đổi ảnh; số ảnh hiện tại/tổng ảnh; mở ảnh lớn, phóng to và thu nhỏ.
- Các mục thuyết minh/chỉ đường/3D nằm trong bảng thao tác thay cho hàng loạt nút dài.
- Đã build Flutter web và cập nhật smgs_web/public/visitor để bản xem trên web có UI mới.

## Kiểm tra
- Web production build: đạt; còn cảnh báo bundle lớn.
- Node tests: 37 đạt, 1 bài tích hợp BE bị bỏ qua theo cấu hình có sẵn.
- Playwright: điều hướng nhóm của Admin, Museum Staff, Curator, System Staff: 4/4 đạt với API giả lập trong bài test, không phải xác nhận E2E với BE thật.
- Flutter gallery: 2/2 đạt (mapping media và đổi/mở/đóng ảnh lớn).
- Flutter release web: đạt. Kiểm tra toàn bộ trước khi sửa hai gợi ý style còn 2 thông tin cũ về dart:html trong Sketchfab; không có lỗi biên dịch.

## Giới hạn định vị — trao đổi cùng đợt UI
GPS không đủ tin cậy để tự xác định khách đang ở phòng nào. UI chỉ dùng điểm đã xác nhận/quét gần nhất; thay nhãn gợi hiểu nhầm là theo dõi vị trí trực tiếp.

Luồng đề xuất, chưa triển khai thêm trong đợt này:
1. GPS gợi ý bảo tàng gần và hiển thị sai số; xác nhận đến bằng nhiều mẫu đo ổn định kết hợp khách xác nhận hoặc QR tại cửa.
2. QR tại phòng/hiện vật cập nhật museum/floor/room/node; so khớp đích để xác nhận đã đến.
3. Chỉ hiển thị vị trí xác nhận gần nhất khi chưa có dữ liệu mới. Không cho điểm vị trí tự chạy giả theo tuyến.
4. Tự động xác định đổi phòng cần hạ tầng và khảo sát thực địa (ví dụ BLE beacon/Wi-Fi RTT), không được coi như đã có trong bản hiện tại.
