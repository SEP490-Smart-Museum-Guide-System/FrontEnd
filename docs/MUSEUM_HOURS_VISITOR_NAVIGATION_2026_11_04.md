# Cập nhật bảo tàng và chỉ đường Visitor — 04/11/2026

## Phạm vi đã sửa

### 1. Tỉnh / thành phố trong form thêm và sửa bảo tàng

- `MuseumCityPicker.jsx` lấy dữ liệu trực tiếp từ `GET /api/museums/cities` của BE, dùng mã tỉnh hai ký tự và tên tỉnh. Không sinh lựa chọn `0` từ chỉ số mảng.
- Hiện trạng thái đang tải; nếu API lỗi hoặc trả dữ liệu không hợp lệ, khóa danh sách và hiện nút **Tải lại tỉnh / thành phố**. Thử lại giữ nguyên các trường đang nhập.
- Chặn gửi form khi chưa chọn mã tỉnh hợp lệ. Danh sách tỉnh do BE cung cấp, không thêm danh sách mẫu ở FE.

### 2. Chọn lịch mở cửa

- Thay ô nhập chuỗi bằng hai bộ chọn giờ gốc của trình duyệt (`type="time"`): **Giờ mở cửa**, **Giờ đóng cửa**; chọn các ngày mở cửa trong tuần bằng checkbox.
- Chặn giờ đóng trước/bằng giờ mở, lịch thiếu một đầu giờ và lịch có giờ nhưng không chọn ngày.
- Lưu vào trường `OpeningHours` hiện có, ví dụ `08:30 - 17:15 (Thứ 3, Thứ 4, Thứ 5, Thứ 6, Thứ 7)`. Không đổi schema DB.
- Đọc được lịch cũ như `08:00 - 17:00`, khoảng ngày viết số hoặc chữ (`Thứ Ba - Chủ Nhật`). Chuỗi lịch phức tạp chưa phân tích được vẫn được giữ nguyên; người dùng chủ động bấm **Chỉnh bằng bộ chọn giờ** để thay thế.
- Đây là lịch giờ mở cửa lặp theo tuần; chưa thêm lịch ngày lễ hoặc nhiều ca trong một ngày.
- Bộ chọn ảnh từ máy/preview/upload lúc lưu ở lần cập nhật trước vẫn được giữ. Xem [tài liệu ảnh đại diện](MUSEUM_COVER_UPLOAD_2026_11_04.md).

### 3. UI Flutter tìm phòng và chỉ đường tới hiện vật

Màn **Tìm hiện vật & chỉ đường** mới có:

- Tìm theo tên hiện vật/phòng; lọc tòa nhà–tầng và phòng trưng bày.
- Hiện đúng phòng, tầng và tòa nhà lấy từ DB.
- Nút **Chỉ đường · tên sơ đồ** mở đúng ID sơ đồ đã xuất bản và chọn sẵn hiện vật đích, không yêu cầu khách biết mã sơ đồ.
- Danh sách sơ đồ đã xuất bản; thông báo rõ khi chưa có sơ đồ hoặc hiện vật chưa gắn điểm đến.
- Trạng thái tải/lỗi/thử lại; không dùng phòng hay tuyến đường mẫu khi API thất bại.

Các lối vào:

1. Chi tiết bảo tàng → **Sơ đồ bảo tàng & Tìm đường hiện vật**.
2. Chi tiết hiện vật → **Vị trí & chỉ đường tới hiện vật**.
3. Tiến trình lượt tham quan → nút bản đồ.
4. Hướng dẫn trong chuyến tham quan → **Xem phòng & chỉ đường trên sơ đồ**.

Trong màn sơ đồ:

- Căn vừa sơ đồ theo màn điện thoại; hỗ trợ phóng/thu và nút **Vừa khung sơ đồ**.
- Khi đang có lượt tham quan, dùng vị trí QR đã ghi nhận và API tính tuyến hiện có của BE.
- Khi xem độc lập, khách chọn **Điểm bạn đang đứng** thủ công từ marker thực tế hoặc quét QR; tính tuyến trên graph sơ đồ. Không mô phỏng theo dõi vị trí trực tiếp.
- Giữ bộ lọc lối đi xe lăn. Hiện lỗi khi ảnh sơ đồ tải thất bại thay vì để bản đồ trống.
- Sửa lỗi `BackendPanel` trả Future trong callback `setState` khiến nút thử lại lỗi ở debug; sửa nền tương tác của danh sách điểm đến.
- Sửa fallback của Vite: `/visitor/` phục vụ đúng trang Flutter, thay vì bị SPA React trả lại trang đăng nhập nghiệp vụ. `/visitor` chuyển hướng sang `/visitor/` và giữ query như `mode=register`.

## Backend đi kèm

Thêm endpoint cần đăng nhập:

```http
GET /api/museums/{museumId}/visitor-directory
Authorization: Bearer <access_token>
```

Phản hồi trong envelope `data` hiện có:

```json
{
  "museumId": 7,
  "museumName": "Tên lấy từ DB",
  "galleries": [
    { "id": 3, "name": "Phòng Đông Sơn", "floorId": 2, "floorName": "Tầng 1", "levelNo": 1, "buildingName": "Nhà A" }
  ],
  "maps": [
    { "id": 5, "name": "Sơ đồ tầng 1", "floorId": 2, "revision": 3, "floorName": "Tầng 1", "buildingName": "Nhà A" }
  ],
  "artifacts": [
    { "id": 11, "name": "Trống đồng", "galleryId": 3, "galleryName": "Phòng Đông Sơn", "floorId": 2, "floorName": "Tầng 1", "buildingName": "Nhà A", "maps": [
      { "id": 5, "name": "Sơ đồ tầng 1", "floorId": 2, "revision": 3, "floorName": "Tầng 1", "buildingName": "Nhà A" }
    ] }
  ]
}
```

Ví dụ trên chỉ mô tả hợp đồng API, không phải dữ liệu fallback đưa vào ứng dụng.

- Chỉ đọc bảo tàng và hiện vật đang hoạt động; không trả nội dung premium hoặc bản nháp.
- Chỉ dùng `IndoorMaps.PublishedJson`, không đọc bản nháp để hiển thị cho Visitor.
- `VisitorMapCatalog` chỉ liên kết hiện vật có đúng một marker đích đang hoạt động, node tồn tại và khớp phòng/tầng khi có cấu hình. Marker trùng hoặc sai vị trí bị loại khỏi liên kết chỉ đường.
- BE dùng các bảng sẵn có; không thêm migration và không sửa dữ liệu DB.

## Điều kiện để thấy đường đi thật

1. Cập nhật cả BE và FE; BE cũ chưa có endpoint `visitor-directory` sẽ báo lỗi tải danh mục.
2. Museum Staff cấu hình tòa nhà/tầng/phòng, gán phòng cho hiện vật, tạo graph đường đi và gắn marker hiện vật vào node.
3. **Xuất bản sơ đồ**. Trang web có `preview=draft` trong ảnh gửi là bản nháp của nhân viên, chưa phải bản Visitor được xem.
4. Visitor đăng nhập, chọn bảo tàng/hiện vật, mở chỉ đường và xác định điểm xuất phát.

Phạm vi hiện tại là sơ đồ trong nhà 2D và tuyến trên cùng một sơ đồ. Chưa có tuyến tự động nối nhiều tầng/sơ đồ hoặc định vị trong nhà theo thời gian thực. Google Maps bên ngoài bảo tàng giữ nguyên luồng cũ.

## Kiểm thử và đóng gói

- Flutter analyze: không có vấn đề.
- Flutter tests: **72 pass, 1 live test skip**. Bốn test mới kiểm tra phòng thực từ API fixture, chọn đúng sơ đồ/đích, chọn xuất phát và tính tuyến, căn vừa sơ đồ, màn 320px với chữ lớn, tải lại lỗi API và lỗi tải ảnh.
- Node tests: **22 pass, 1 live test skip**; có kiểm tra đọc/lưu giờ, ngày trong tuần, lịch cũ và lịch sai.
- Playwright Edge: **14/14 pass**, gồm thử lại danh sách tỉnh, xác thực và lưu lịch, upload ảnh, các luồng web đã có và kiểm tra `/visitor/` khởi động Flutter thực. Các kiểm thử nghiệp vụ dùng API fixture.
- BE solution build: **0 warning, 0 error**.
- `SMGS.IndoorMapChecks`: pass graph, tuyến một chiều/xe lăn, liên kết đúng phòng/tầng/node, loại marker bất hoạt/trùng và yêu cầu đăng nhập.
- `SMGS.MuseumImageChecks`: sau đồng bộ BE `dev` tại `4cb34b8`, pass HTTP multipart thực qua service/repository thật, key R2, đọc ảnh, quyền, ảnh sai, cleanup và lỗi kho 503; dùng EF InMemory/storage fixture, chưa chứng minh rollback PostgreSQL thật.
- Lint web chạy thành công, còn warning cũ trong các component hiện có.
- Flutter web release và React production build thành công. Đã cập nhật `smgs_web/public/visitor/`; hash `main.dart.js` khớp giữa output Flutter, thư mục public và output React. Còn cảnh báo kích thước bundle React đã có.

Các kiểm thử này không xác nhận end-to-end với PostgreSQL/JWT/camera QR thật. Lần cập nhật này không chạy migration, không ghi DB thật, không tự commit/push/deploy.

Build bản Visitor xem bằng web, rồi đóng gói portal:

```powershell
cd D:\SEP409\FrontEnd
.\tools\update-visitor-web.ps1 -Flutter C:\dev\flutter\bin\flutter.bat
cd .\smgs_web
npm run build
npm run dev -- --host 127.0.0.1 --port 5173
```

Mở `http://127.0.0.1:5173/` để xem web nghiệp vụ; mở `http://127.0.0.1:5173/visitor/` để xem UI Flutter Visitor ngay trong trình duyệt. BE local sử dụng cổng 5169 theo cấu hình hiện tại.

Khi FE/BE triển khai khác host, cấu hình `VITE_API_BASE_URL` cho React, `-ApiBaseUrl` khi chạy script build Flutter và CORS bên BE. Không đặt URL local trong bản production.
