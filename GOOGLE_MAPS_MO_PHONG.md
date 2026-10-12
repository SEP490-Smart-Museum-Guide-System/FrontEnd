# Google Maps: mô phỏng hiển thị bảo tàng và chỉ đường

## Phạm vi đã làm

- Cổng web của **Quản trị viên** có mục **Bảo tàng & Google Maps**.
- Quản trị viên bật hoặc tắt trạng thái công khai từng bảo tàng. Bản đồ mô phỏng chỉ vẽ ghim của các bảo tàng đang công khai.
- Nhân viên bảo tàng xem được trạng thái công khai và dùng nút **Chỉ đường** để kiểm tra liên kết.
- Ứng dụng Flutter của **Khách tham quan** có nút **Chỉ đường đến bảo tàng**. Nút chỉ xuất hiện khi `googleMapsVisible = true` và mở Google Maps bằng tọa độ của bảo tàng.
- Cổng web chỉ có ba role nghiệp vụ: Quản trị viên, Nhân viên bảo tàng và Nhân viên hệ thống. Màn hình đăng nhập có nút **Xem trước giao diện Khách trên web** để kiểm tra UI mobile/chỉ đường khi chưa có simulator; đây không phải role web.
- Hiện vật, phòng trưng bày, vị trí/icon trong nhà và dữ liệu vận hành không được đưa lên bản đồ công khai.

## Dữ liệu mô phỏng hiện tại

| Bảo tàng | Trạng thái trên Google Maps |
| --- | --- |
| Bảo tàng Lịch sử Quốc gia | Hiển thị |
| Bảo tàng Hồ Chí Minh | Hiển thị |
| Bảo tàng Mỹ thuật Việt Nam | Ẩn |

## Lưu ý khi nối backend

Hiện trạng thái bật/tắt ở web là state của React để demo UI; chưa đồng bộ sang Flutter vì hệ thống chưa có backend. Khi triển khai API, backend nên chỉ trả về danh sách bảo tàng có `googleMapsVisible = true` cho role Khách.

Gợi ý trường dữ liệu cho mỗi bảo tàng:

```json
{
  "googleMapsVisible": true,
  "latitude": 21.02591,
  "longitude": 105.85794
}
```

Không cần Google Maps API key cho luồng **mở chỉ đường** vì app dùng deep link `https://www.google.com/maps/dir/?api=1`. Nếu sau này nhúng bản đồ Google tương tác thật hoặc Places API, cần tạo API key, cấu hình domain/package restriction và bật billing trên Google Cloud.
