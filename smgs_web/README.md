# SMGS · Cổng nghiệp vụ web

Hệ thống có **4 vai trò**: Admin, Museum Staff, System Staff và Visitor. Ba vai trò đầu dùng cổng web React + Vite; Visitor dùng ứng dụng Flutter mobile. Nút đổi vai trò trên web chỉ để xem thử giao diện khi backend và xác thực chưa kết nối.

## Phạm vi giao diện

- **Admin:** tổng quan toàn hệ thống, người dùng và phân quyền, bảo tàng, giao dịch, nhật ký.
- **Museum Staff:** thông tin và không gian bảo tàng được phân công; hiện vật, media, QR, vị trí/biểu tượng trên bản đồ; tour và nội dung miễn phí/nâng cao; tạo và duyệt nội dung AI; feedback và doanh thu của bảo tàng mình.
- **System Staff:** hỗ trợ Visitor, xử lý khiếu nại và yêu cầu hoàn tiền, đối soát giao dịch, kiểm duyệt feedback, theo dõi lỗi vận hành và chất lượng AI trên toàn hệ thống.
- **Visitor:** giao diện Flutter mobile trong `../smgs_mobile`, không có màn nghiệp vụ web.

Các dữ liệu và thao tác hiện được mô phỏng trên FE, lưu trong trạng thái React của phiên làm việc. Chưa có API hoặc cổng thanh toán thật. Hoàn tiền trên màn demo chỉ đổi trạng thái dữ liệu mẫu.

## Chạy thử trên web

```powershell
cd D:\SEP409\FrontEnd\smgs_web
npm install
npm run dev -- --host 127.0.0.1 --port 8090
```

Mở `http://127.0.0.1:8090/`. Kiểm tra bản đóng gói bằng `npm run build` và mã nguồn bằng `npm run lint`.

## Upload bộ ảnh 3D trên production

Đặt `VITE_UPLOAD_API_BASE_URL` thành HTTPS BE có `/api` để multipart upload không đi qua proxy CDN. Các API JSON/polling vẫn dùng `VITE_API_BASE_URL`; upload giữ JWT của người đăng nhập, không đưa khóa AI vào trình duyệt. BE phải thêm đúng origin FE vào `Cors:AllowedOrigins`. Mẫu hai cấu hình nằm trong `deploy/scan-upload.env.example`; áp dụng BE trước, sau đó redeploy FE với biến build mới.

Scan upload có thời hạn riêng 15 phút, rồi nhận mã job và polling độc lập đến khi dựng xong; không giữ request tải ảnh trong suốt quá trình dựng 3D. Khi mất phản hồi upload, FE kiểm tra job đã được nhận và không tự gửi lại ảnh. Nếu chưa xác định được, người dùng kiểm tra lại danh sách job trước khi gửi tiếp.
