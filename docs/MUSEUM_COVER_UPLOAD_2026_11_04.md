# Chọn ảnh đại diện bảo tàng từ máy — 04/11/2026

## Giao diện

- Form thêm và sửa bảo tàng dùng **Chọn ảnh từ máy / Chọn ảnh khác**, thay cho nhập đường dẫn.
- Xem trước ảnh, tên file, dung lượng; có thể bỏ ảnh vừa chọn để giữ ảnh hiện tại.
- Chấp nhận PNG/JPEG/WebP tối đa 15 MB. Object URL chỉ dùng xem trước và được thu hồi khi đổi/đóng form; không lưu blob URL vào DB.
- File và thông tin bảo tàng được gửi chung khi bấm lưu. Chọn ảnh rồi hủy không upload hoặc thay đổi dữ liệu.
- Khóa gửi trùng trong lúc lưu; lỗi server giữ lại form và ảnh để thử lại.
- Đồng bộ danh sách tỉnh/thành với response code/name của BE để form có thể gửi đúng mã.

## API và lưu trữ

FE và BE cần được cập nhật cùng nhau vì form sử dụng các endpoint multipart mới:

| Endpoint | Quyền | Tác dụng |
| --- | --- | --- |
| POST /api/museums/with-image | Admin | Tạo thông tin bảo tàng với file tùy chọn. |
| PUT /api/museums/{id}/with-image | Admin / Museum Staff được phân công ở cấp bảo tàng | Lưu thông tin và file tùy chọn trong một yêu cầu. |
| POST /api/museums/{id}/image | Cùng quyền sửa ảnh | Upload trực tiếp ở thẻ thông tin bảo tàng có sẵn. |
| DELETE /api/museums/{id}/image | Cùng quyền sửa ảnh | Gỡ liên kết ảnh đại diện. |
| GET /api/museums/{id}/image/{name} | Public khi bảo tàng hoạt động; người quản lý có quyền với ảnh bảo tàng ẩn | Đọc ảnh R2 có tên do server sinh, MIME đúng và nosniff. |

Multipart gồm các trường thông tin hiện có và file có tên trường `file`. Header Content-Type do browser sinh để giữ boundary. Các endpoint JSON cũ được giữ để tương thích với bên gọi cũ.

BE kiểm tra quyền trước khi ghi file, giải mã nội dung thật bằng SkiaSharp, đối chiếu định dạng/đuôi file, giới hạn 15 MB và 8.000 pixel mỗi chiều/20 triệu pixel. Tên lưu là GUID; không dùng đường dẫn do người dùng cung cấp.

Sau khi đồng bộ BE `dev` với `origin/dev` tại `4cb34b8`, các endpoint form thuộc `MuseumFormsController`; các endpoint ảnh trực tiếp giữ tại `MuseumImagesController` của remote. Khi lưu kèm file, metadata và URL nằm trong transaction DB, file lên R2 với ID bảo tàng thực; lỗi lưu sẽ dọn object mới. Giữ ảnh cũ theo chính sách remote vì có thể có tham chiếu chung.

Storage hiện dùng `IFileStorageService`/Cloudflare R2 theo cấu hình `CloudflareR2` của BE; không ghi ảnh mới vào disk local. Key ảnh là `museums/{museumId}/images/{guid}.{ext}`. Cấu hình `MuseumImages:StoragePath` của bản thử nghiệm trước không còn dùng.

## Kiểm tra

- Build BE thành công.
- SMGS.MuseumImageChecks pass: HTTP multipart thật, service/repository thật, lưu/đọc bytes qua storage fixture, quyền 401/403, từ chối ảnh sai, dọn object mới khi lưu URL thất bại, giữ ảnh cũ, gỡ ảnh và lỗi kho trả 503.
- Test HTTP dùng EF InMemory, storage và authentication fixture; không xác nhận PostgreSQL/R2/JWT thật hay rollback transaction PostgreSQL.
- Ba test browser mới pass: thêm bảo tàng kèm file/preview, sửa lỗi rồi thử lại giữ file, chặn ảnh không hợp lệ và hủy không lưu.
- Hồi quy toàn bộ test browser: **14/14 pass**, gồm nghiệp vụ, ảnh, tỉnh thành/giờ và khởi động Flutter web.
- Node test: 22 pass, 1 live auth skip. Lint và React production build thành công; vẫn có các warning lint/bundle đã có.

Chạy lại test BE:

```powershell
cd D:\SEP409\BackEnd\Smart_Museum_Guide_System
dotnet run --project tests/SMGS.MuseumImageChecks
```

Chạy test web và build:

```powershell
cd D:\SEP409\FrontEnd\smgs_web
npm test
npm run test:e2e
npm run build
```

Lần thay đổi này không chạy migration, không ghi DB thật và không commit/push.
