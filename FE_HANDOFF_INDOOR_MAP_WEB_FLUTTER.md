# Bàn giao FE — Quản lý bản đồ Web & bản đồ khách tham quan Flutter

Ngày: 28/10/2026. Đặc tả giao diện, thao tác và tích hợp API dành cho FE Web và Flutter.

## 1. Mục tiêu và phạm vi

Triển khai hai giao diện:

1. **Web Admin / Museum Staff:** tạo và chỉnh sửa bản đồ trong bảo tàng, theo bố cục và cách thao tác mô tả trong tài liệu này.
2. **Mobile Flutter / Visitor:** xem bản đồ, chọn hiện vật, xác định vị trí bằng QR và tìm đường. Triển khai mobile native với bản đồ và bottom sheet phù hợp màn hình điện thoại.

Dùng dữ liệu thật từ BE khi tích hợp; không đưa danh sách hiện vật hoặc bản đồ mẫu vào luồng thực tế.

**Bắt buộc triển khai quét QR trên Flutter để xác định vị trí xuất phát.** BE đã có API scan hiện vật; FE cần làm camera, xử lý kết quả scan và ánh xạ vị trí theo mục 6.

Tất cả nút, nhãn, hướng dẫn, trạng thái và lỗi nghiệp vụ dùng tiếng Việt. Phạm vi tìm đường hiện tại chỉ trong một sơ đồ; chưa có tìm đường xuyên tầng hoặc định vị liên tục.

## 2. Cách sử dụng tài liệu và tích hợp BE

Đây là đặc tả độc lập: người triển khai không cần mã nguồn hoặc trang giao diện thử nghiệm. Bố cục, thao tác, dữ liệu và API được mô tả đầy đủ bên dưới.

- Web dùng tài khoản Admin hoặc Museum Staff được phân công đúng bảo tàng.
- Flutter dùng tài khoản Visitor đã đăng nhập để đọc bản đồ xuất bản.
- Cấu hình API base theo môi trường; các endpoint trong tài liệu nằm dưới `/api`.
- Lấy ID từ dữ liệu BE, không hardcode ID bảo tàng/sơ đồ/hiện vật.
- Xem thử bản nháp chỉ dành cho tài khoản quản lý và chỉ đọc dữ liệu đã lưu.

### Trình tự kết nối API

| Luồng giao diện | Chuỗi API / xử lý |
|---|---|
| Mở quản lý | `GET me/museums` → chọn bảo tàng → `GET museums/{museumId}/indoor-structure` và `GET museums/{museumId}/indoor-maps` |
| Mở sơ đồ | `GET indoor-maps/{id}/draft` + `GET indoor-maps/{id}/links` → `GET indoor-maps/{id}/image?key={imageKey}` |
| Tạo sơ đồ | Xác định cấu trúc; chọn/tạo tầng thực tế nếu cần → `POST museums/{museumId}/indoor-maps` → upload ảnh |
| Gắn hiện vật | Chọn từ `artifacts` của `/links` → lưu `artifactId` và `nodeId` vào graph → `PUT indoor-maps/{id}/draft` |
| Thử tuyến trong editor | Lưu draft → `POST indoor-maps/{id}/preview-route` → vẽ tuyến theo `nodeIds` |
| Xuất bản | Lưu draft → `POST indoor-maps/{id}/publish` với revision mới nhất |
| Xem thử phía khách trong Web quản lý | Đọc draft và ảnh draft bằng quyền staff/admin → render màn hình chỉ đọc; tính tuyến trên graph đó nếu cần |
| Flutter mở map đã biết ID | `GET indoor-maps/{id}/published` → `GET indoor-maps/{id}/published/image?key={imageKey}` |
| Flutter quét QR trong map đang mở | Parse QR → `GET artifacts/scan/{qrCode}` → đối chiếu `data.id` với `marker.artifactId` → lấy `marker.nodeId` làm điểm xuất phát |
| Flutter chỉ đường | Tính Dijkstra trên graph published theo mục 7.5 → vẽ tuyến đến node liên kết của đích |

Tự tìm sơ đồ từ bảo tàng hoặc QR khi chưa biết mapId còn cần API BE bổ sung tại mục 7.3. Không dùng endpoint quản lý có quyền staff cho Visitor.

## 3. Hiểu đúng mô hình điểm và đường

| Thành phần | Vai trò |
|---|---|
| Điểm dẫn đường — node | Vị trí trên mạng lối đi: hành lang, ngã rẽ, cửa, cầu thang… |
| Đoạn đường — edge | Nối hai node, có chiều di chuyển và thuộc tính phù hợp xe lăn |
| Điểm đánh dấu — marker | Vị trí hiển thị hiện vật hoặc tiện ích trên sơ đồ |
| Liên kết `marker.nodeId` | Node dùng để tiếp cận marker hoặc làm điểm xuất phát sau quét QR |
| Liên kết `marker.artifactId` | Hiện vật có sẵn trong database, dùng để đối chiếu kết quả quét QR |

**Nối điểm chỉ nối node với node.** Marker được gắn node bằng trường “Điểm dẫn đường liên kết”; không tạo edge từ marker đến node. Nhiều hiện vật gần nhau có thể dùng chung một node nếu thật sự tiếp cận được từ cùng vị trí.

Ví dụ: hiện vật A và B cùng liên kết node X. Từ cùng một điểm xuất phát, chọn A hoặc B sẽ cho cùng tuyến đến X; vị trí marker của A và B vẫn riêng biệt. Tuyến kết thúc tại X, không tự nối đoạn thẳng xuyên tường đến marker. Hai hiện vật ở hai phía tường cần node phù hợp riêng.

**QR chỉ thuộc hiện vật.** Dùng lại QR hiện vật đang có. Không tạo QR cho hành lang, cửa, cầu thang, thang máy hoặc tiện ích; không thêm công cụ “Thêm QR định vị” độc lập.

## 4. Web — quản lý bản đồ

### 4.1. Bố cục cần giữ

- Tiêu đề “Bản đồ trong bảo tàng”, mô tả ngắn, khu thông báo lỗi/thành công.
- Chọn bảo tàng theo quyền, cấu trúc thực tế và sơ đồ hiện có.
- Tên sơ đồ, trạng thái bản nháp/đã xuất bản, phiên bản và trạng thái chưa lưu.
- Thanh tải ảnh và hành động lưu/xuất bản.
- Toolbar công cụ nằm phía trên sơ đồ.
- Sơ đồ chiếm phần lớn chiều ngang, bảng **Thuộc tính** bên phải khoảng 280px. Khi màn hình hẹp, bảng thuộc tính xuống dưới.
- Khu thử đường đi ở dưới: điểm bắt đầu, điểm kết thúc, tùy chọn xe lăn, nút xem thử.

### 4.2. Bảo tàng, tòa nhà và tầng

1. Lấy danh sách bảo tàng được phép quản lý từ BE.
2. Đọc cấu trúc `unknown`, `single` hoặc `floors`.
3. Nếu `unknown`, yêu cầu nhân viên xác định **Mặt bằng chung** hay **Theo tòa nhà và tầng**.
4. `single`: tạo/chọn một sơ đồ chung, `floorId = null`, không hiện bộ chọn tầng thừa.
5. `floors`: dùng tòa nhà và tầng thực tế; chỉ tạo sơ đồ sau khi đã chọn tầng. Một sơ đồ mỗi tầng.

Không suy ra “không có tầng” chỉ vì database chưa có dữ liệu tầng. Không tự tạo tầng trệt/tầng 1 hoặc tòa nhà giả. Không tự đổi cấu trúc đã có dữ liệu phụ thuộc. Chỉ Admin thấy chức năng phân công nhân viên quản lý.

### 4.3. Thanh hành động và công cụ

| Nút / công cụ | Hành vi |
|---|---|
| Tải ảnh sơ đồ | PNG/JPG tối đa 10 MB; giữ đúng tỷ lệ ảnh. Xử lý xác nhận nếu thay ảnh ảnh hưởng tọa độ |
| Lưu bản nháp | Gửi toàn bộ graph cùng `revision`, cập nhật revision theo response |
| Tải lại | Đọc lại bản nháp; hỏi trước nếu sẽ bỏ thay đổi chưa lưu |
| Xuất bản | Chỉ xuất bản cấu hình đã lưu; hiển thị lỗi validation/cảnh báo từ BE |
| Ngừng xuất bản | Xác nhận trước khi ngừng cung cấp bản đồ cho khách |
| Xem thử phía khách | Mở giao diện thử với map đang chọn, đọc bản nháp đã lưu bằng quyền staff/admin |
| Thêm điểm đánh dấu | Mặc định loại hiện vật; click ảnh để đặt marker |
| Thêm điểm dẫn đường | Đặt node trên lối đi thực tế |
| Nối điểm | Click lần lượt hai node để tạo edge; không nối chính nó hoặc trùng hướng |
| Thêm cầu thang / Thêm thang máy | Đặt node loại tương ứng; chưa tạo kết nối xuyên tầng |
| Kéo sơ đồ | Công cụ thay thế cho thao tác giữ nút giữa chuột |
| Xóa đối tượng | Xóa đối tượng đang chọn; xử lý liên kết phụ thuộc |
| Phóng to / Thu nhỏ / Vừa khung | Thay đổi khung nhìn, không thay đổi dữ liệu tọa độ |

Khi xóa node: xóa các edge nối tới node đó, bỏ `nodeId` ở marker liên quan nhưng không xóa marker/hiện vật trong database. Sau đó phải liên kết lại các marker cần dẫn đường trước khi xuất bản.

### 4.4. Thao tác chuột và bàn phím — bắt buộc

- Giữ chuột trái trên điểm để kéo trực tiếp; không có bước phải bật “Chọn / Di chuyển điểm”.
- Kéo điểm hoạt động cả khi đang bật công cụ thêm/nối; không vô tình thêm điểm hoặc tạo cạnh khi kéo.
- Phân biệt click và drag bằng ngưỡng di chuyển nhỏ; dùng ngưỡng khoảng 4px.
- Đặt một điểm xong tự thoát chế độ thêm. Bấm lại công cụ đang bật hoặc Escape để thoát.
- Giữ nút giữa chuột (nút lăn) và kéo để di chuyển bản đồ ở mọi công cụ.
- Ctrl + lăn chuột để zoom quanh con trỏ. Chặn zoom trình duyệt chỉ khi thao tác trên vùng bản đồ.
- Khi không chọn công cụ, kéo chuột trái trên nền cũng pan bản đồ.
- Giữ các nút pan/zoom làm phương án thay thế; hỗ trợ chọn đối tượng bằng danh sách, sửa tọa độ bằng ô số và thêm điểm ở giữa sơ đồ bằng bàn phím.
- Khi rời trang/đổi sơ đồ có thay đổi chưa lưu: cảnh báo trước khi bỏ dữ liệu.

### 4.5. Bảng thuộc tính

**Chung cho node/marker:** chọn đối tượng, tên, loại, tọa độ X/Y chuẩn hóa từ 0 đến 1.

**Node:** loại `corridor`, `intersection`, `door`, `entrance`, `stair`, `elevator`; hiển thị nhãn tiếng Việt.

**Marker:** loại `artifact`, `gallery`, `entrance`, `exit`, `restroom`, `information`, `stair`, `elevator`.

- Loại hiện vật: dropdown hiện vật từ API `/links`, chỉ đúng phạm vi bảo tàng. Chọn hiện vật thì lưu `artifactId`, lấy tên hiện vật làm nhãn mặc định.
- Loại phòng trưng bày: dropdown phòng, lưu `galleryId`.
- Dropdown **Điểm dẫn đường liên kết** lấy node của cùng sơ đồ.
- Checkbox **Là điểm đến có thể dẫn đường**, **Đang hoạt động**.
- Hiện vật phải có `artifactId` và node liên kết trước khi xuất bản, kể cả khi bỏ checkbox điểm đến.
- Đổi loại marker phải bỏ liên kết hiện vật/phòng không còn phù hợp.
- Nút **Tải QR hiện vật** tải lại QR hiện có, không sinh mã mới; chỉ bật khi marker đã lưu, đang hoạt động và có liên kết hiện vật. Nếu trang quản lý hiện vật đã có nút tải QR, có thể thống nhất bỏ nút trùng khỏi editor.
- Marker `qr` cũ: cho người dùng chuyển sang hiện vật và gắn hiện vật thật hoặc loại khác; không tự xóa hay gán đại.

**Edge:** hiển thị đầu/cuối, nút **Đảo hướng**, checkbox **Đi được hai chiều** và **Phù hợp xe lăn**.

## 5. Flutter — bản đồ dành cho Visitor

### 5.1. Thiết kế và bố cục mobile

Phong cách giao diện: nền kem `#f7f5f0`, thẻ trắng ngà, chữ tối, điểm đánh dấu đỏ nâu `#873c32`, nút chính đỏ nâu `#7b3b31`, tuyến và điểm đang chọn xanh lá `#227c64`, vị trí xuất phát xanh dương `#2563eb`, bo góc mềm.

Chuyển bố cục hai cột desktop thành:

1. App bar có quay lại, tên bảo tàng/sơ đồ.
2. Tìm kiếm hiện vật/tiện ích; bộ chọn tầng chỉ khi có tầng thật và dữ liệu bản đồ xuất bản tương ứng.
3. Bản đồ chiếm vùng chính; pinch để zoom, kéo để pan; nút vừa khung và quay về vị trí đã xác định.
4. Nút dễ thấy **Quét QR xác định vị trí**.
5. Bottom sheet cho danh sách điểm đến, thông tin điểm được chọn và nút **Chỉ đường đến đây**. Giữ bản đồ còn nhìn được khi sheet thu gọn.
6. Tùy chọn **Lối đi phù hợp xe lăn**, chú thích màu và trạng thái tuyến.

Có thể dùng `InteractiveViewer` kết hợp `Stack`/`CustomPainter`, hoặc cơ chế tương đương trong dự án. Ảnh, marker và tuyến phải cùng một hệ biến đổi. Không kéo sửa marker trên ứng dụng Visitor.

### 5.2. Hành vi

- Chỉ hiển thị marker đang hoạt động; bấm marker và bấm mục trong danh sách phải chọn cùng một đối tượng.
- Tìm theo tên; có trạng thái “Không có địa điểm phù hợp”.
- Khi chọn đích: hiện tên, loại và khả năng dẫn đường. Marker không có node hoặc không là điểm đến thì không cho bắt đầu tuyến.
- Chưa có vị trí xuất phát: hướng dẫn quét QR; không tự giả định khách đang ở lối vào hoặc node đầu tiên.
- Đổi đích, vị trí hoặc tùy chọn xe lăn phải xóa/tính lại tuyến cũ, không để tuyến sai còn hiển thị.
- Tuyến kết thúc tại node liên kết. Khi xuất phát và đích chung node, báo “Bạn đang ở điểm tiếp cận địa điểm này”.
- Không có đường: báo rõ và cho chọn lại; không vẽ đường thẳng thay thế.
- Không hiển thị toàn bộ node/edge phục vụ biên tập cho khách. Chỉ cần marker, vị trí xuất phát, tuyến đang chọn.
- Nếu thêm ô chọn node thủ công để QA thì chỉ bật trong chế độ kiểm thử. Flutter thực tế xác định vị trí bằng quét QR.
- Visitor thực tế không được đọc bản nháp; xem thử bản nháp chỉ dành cho tài khoản quản lý.

## 6. Flutter — quét QR xác định vị trí (phải triển khai thêm)

### 6.1. Luồng xử lý

1. Khách bấm **Quét QR xác định vị trí**.
2. Xin quyền camera khi cần; mở màn hình quét có khung ngắm, nút đóng và bật/tắt đèn nếu thiết bị hỗ trợ.
3. Đọc QR trên hiện vật, khóa xử lý trùng trong lúc đang giải mã/gọi API.
4. QR hiện tại chứa URL dạng `{apiHost}/api/artifacts/scan/{qrCode}`. Parse URI, kiểm tra định dạng và trích `qrCode`; gọi scan qua API base của ứng dụng. Không mở hoặc gửi JWT đến URL bất kỳ lấy từ QR.
5. Gọi `GET /api/artifacts/scan/{qrCode}` (encode path segment đúng cách). Response `data.id` là ID hiện vật; `data.museumId` xác định bảo tàng.
6. Trong snapshot đã xuất bản, tìm marker có `type == artifact`, `isActive == true`, `artifactId == data.id`, đúng museum và có `nodeId` tồn tại.
7. Đặt `fromNodeId = marker.nodeId`, ghi nhận hiện vật vừa quét, đóng camera và hiển thị vị trí lên bản đồ.
8. Báo **“Đã xác định vị trí tại [tên hiện vật]”**, đưa bản đồ về vùng đó. Dùng node cho tính tuyến; có thể nhấn mạnh thêm marker hiện vật để giải thích vị trí quét.
9. Giữ đích khách đã chọn nếu còn cùng sơ đồ và hợp lệ, cập nhật tuyến từ vị trí mới; nếu đổi sơ đồ thì xóa đích/tuyến cũ.

QR xác nhận một vị trí tại thời điểm quét. Không có GPS/BLE/PDR trong phạm vi này, không tự cho chấm “Bạn ở đây” chạy theo khách. Sau khi khách di chuyển, cho **Quét lại QR** và nhắc vị trí là lần xác định gần nhất.

### 6.2. Tình huống cần xử lý

| Tình huống | Hành vi |
|---|---|
| Từ chối camera | Giải thích cần camera; có thử lại hoặc mở cài đặt theo trạng thái quyền, không lặp popup vô hạn |
| Đóng camera / app vào nền | Dừng camera và giải phóng tài nguyên; không thay vị trí cũ |
| QR ngoài hệ thống / sai định dạng | “Mã QR không thuộc hệ thống bảo tàng” |
| QR không còn hợp lệ / hiện vật không tìm thấy | Thông báo, cho quét lại; không đặt vị trí mới |
| Hiện vật có trong DB nhưng chưa gắn sơ đồ | “Hiện vật này chưa có vị trí trên bản đồ” |
| Marker không hoạt động hoặc thiếu node | Không dùng để định vị; thông báo chưa hỗ trợ vị trí |
| Quét ở bảo tàng/sơ đồ khác | Thông báo và cho chuyển sang sơ đồ xuất bản tương ứng nếu lấy được; không dùng ID node của sơ đồ khác |
| Một hiện vật khớp nhiều marker | Không chọn phần tử đầu tiên tùy ý; cần BE đảm bảo duy nhất hoặc có luồng chọn vị trí rõ ràng |
| Mất mạng / timeout | Hiển thị thử lại, giữ vị trí trước đó và nói rõ chưa cập nhật |
| Camera đọc cùng QR nhiều lần | Chỉ xử lý một yêu cầu, tránh nhiều màn hình/thông báo chồng nhau |

QR lấy từ hiện vật thật, không phải ID node/marker. Không dùng `mapX`, `mapY` legacy trong response scan để định vị module mới; dùng marker/node từ snapshot.

### 6.3. Kiểm thử trên điện thoại thật

- Dùng API host mà điện thoại truy cập được; `localhost`/`127.0.0.1` trên điện thoại trỏ về chính điện thoại.
- QR in/tải để test phải dùng host đúng môi trường. Không hardcode host máy dev vào app.
- Khai báo quyền camera Android/iOS theo framework và package được dự án lựa chọn.
- Test quyền lần đầu, từ chối, từ chối vĩnh viễn, quay lại từ nền, quét liên tục và lỗi mạng.

## 7. Hợp đồng dữ liệu và API hiện có

API JSON dùng wrapper `{ statusCode, message, data }`; ảnh trả bytes PNG. API indoor cần JWT, kể cả đọc published; Visitor không có quyền draft/links/quản lý.

### 7.1. Web quản lý — đường dẫn dưới `/api`

| Method | Endpoint | Nội dung |
|---|---|---|
| GET | `me/museums` | Bảo tàng được quản lý |
| GET / PUT | `museums/{museumId}/indoor-structure` | Đọc cấu trúc / gửi `{layout}` |
| POST | `museums/{museumId}/buildings` | `{name}` |
| POST | `museums/{museumId}/floors` | `{buildingId,levelNo,name}` |
| POST | `museums/{museumId}/indoor-staff` | `{userId}`; Admin |
| GET / POST | `museums/{museumId}/indoor-maps` | Danh sách / tạo với `{floorId,name}` |
| GET | `indoor-maps/{id}/draft` | Bản nháp |
| GET | `indoor-maps/{id}/links` | `{artifacts,galleries}`; mỗi mục `{id,name}` |
| PUT | `indoor-maps/{id}/draft` | `{revision,nodes,markers,edges}` |
| POST | `indoor-maps/{id}/image` | Multipart `file`, `revision`, `confirm` |
| GET | `indoor-maps/{id}/image?key={imageKey}` | Ảnh nháp đúng phiên bản |
| POST | `indoor-maps/{id}/preview-route` | `{revision,fromNodeId,toNodeId,accessibleOnly}` |
| POST | `indoor-maps/{id}/publish` / `unpublish` | `{revision}` |
| GET | `indoor-maps/{id}/qr/{markerId}` | QR hiện vật đã liên kết, không tạo QR độc lập |

### 7.2. Visitor — API đã có

| Method | Endpoint | Nội dung |
|---|---|---|
| GET | `indoor-maps/{id}/published` | Snapshot đã xuất bản; yêu cầu đăng nhập |
| GET | `indoor-maps/{id}/published/image?key={imageKey}` | Ảnh của snapshot; gửi JWT |
| GET | `artifacts/scan/{qrCode}` | Thông tin hiện vật: `id,museumId,museumName,name,qrCode,contents,…`; hiện cho phép anonymous |
| GET | `artifacts/{id}/qr-image` | Ảnh QR hiện vật để chuẩn bị in/test |

Flutter tải ảnh bằng client có header Authorization; không giả định URL ảnh là public. Khi nhận 409 do ảnh đã đổi, tải lại snapshot và ảnh tương ứng.

### 7.3. Những phần chưa có — cần phối hợp BE

- **API danh sách sơ đồ xuất bản theo bảo tàng dành cho Visitor chưa có trong module hiện tại.** Endpoint danh sách hiện có là staff/admin. Cần thống nhất API Visitor để chọn map/tầng, không gọi endpoint quản lý bằng tài khoản khách.
- **API resolve hiện vật → sơ đồ xuất bản/node chưa có.** Khi đã biết mapId, FE có thể scan rồi đối chiếu marker trong snapshot đó. Để quét QR từ bất kỳ đâu và tự mở đúng sơ đồ, cần API resolve hoặc danh sách snapshot published đủ để tra cứu. Thống nhất contract với BE trước khi tích hợp; không coi đường dẫn đề xuất là API đã tồn tại.
- **API route trên snapshot published chưa có.** Flutter cần triển khai Dijkstra trên graph published theo mục 7.5. Không gọi `preview-route` cho Visitor: endpoint đó dùng bản nháp và quyền staff. Nếu chuyển tính tuyến về BE, cần bổ sung endpoint published với kiểm tra phiên bản.
- Cần thống nhất quy tắc một hiện vật xuất hiện ở nhiều marker/sơ đồ. Hiện không được giả định database đã ràng buộc duy nhất.
- Chưa có API/kết nối tìm đường xuyên tầng. Chỉ hiển thị lựa chọn tầng khi có dữ liệu thật; không vẽ tuyến nối tầng giả.

Các thiếu hụt trên không cản trở thử một mapId đã biết, nhưng phải giải quyết trước khi hoàn thiện luồng Visitor tự chọn bảo tàng/quét QR mở đúng map.

### 7.4. Hình dạng document

```text
MapDocument:
  id, museumId, floorId (nullable), name, revision,
  imageKey, imageWidth, imageHeight, publishedAt,
  nodes[], markers[], edges[], warnings[]

Node:
  id (UUID), label, type, x, y

Marker:
  id (UUID), label, type, x, y,
  artifactId (nullable), galleryId (nullable), nodeId (nullable UUID),
  isDestination, isActive

Edge:
  id (UUID), fromNodeId, toNodeId, bidirectional, isAccessible
```

ID bảo tàng/hiện vật/sơ đồ là số, ID node/marker/edge là UUID. Không thay UUID sau mỗi lần render/lưu.

### 7.5. Tọa độ và tìm đường

- X/Y chuẩn hóa `[0,1]` theo ảnh gốc. Khi render: `px = x * chiều_rộng_ảnh_render`, `py = y * chiều_cao_ảnh_render`, cộng offset nếu ảnh có khoảng trống do fit.
- Pan/zoom chỉ thay đổi phép biến đổi hiển thị, không ghi lại tọa độ dữ liệu.
- Khi kéo điểm editor, đổi tọa độ chuột ngược qua pan/zoom rồi chuẩn hóa.
- Tính trọng số cạnh bằng `sqrt(((x1-x2)*imageWidth)^2 + ((y1-y2)*imageHeight)^2)` để giữ đúng tỷ lệ ảnh.
- Dijkstra phải tôn trọng `bidirectional`; chỉ thêm cạnh ngược khi true. Khi bật xe lăn, bỏ cạnh `isAccessible == false`.
- Không tự nối các node gần nhau. Ảnh không chứa dữ liệu tường có thể tự suy luận.
- Chi phí đường đi là đơn vị pixel theo ảnh, **không phải mét**; chưa hiển thị số mét hoặc ETA khi chưa có hiệu chuẩn.

## 8. Trạng thái và an toàn dữ liệu

- Có loading, empty, error, retry; không âm thầm chuyển sang dữ liệu mẫu khi API thật lỗi.
- 401: yêu cầu đăng nhập lại. 403: báo thiếu quyền. 404: không tìm thấy/chưa xuất bản. 409: dữ liệu đã thay đổi, yêu cầu tải lại thay vì ghi đè. 422: không có tuyến.
- Dùng revision mới từ response sau lưu/upload/publish. Không bỏ kiểm tra concurrency.
- Lưu draft không thay đổi snapshot phục vụ khách. Khách chỉ thấy thay đổi sau publish.
- Hủy request cũ hoặc bỏ response lỗi thời khi đổi bảo tàng/sơ đồ; không hiển thị ảnh và graph khác phiên bản.
- Không đưa credential mẫu vào tài liệu triển khai hoặc hardcode vào ứng dụng.

## 9. Checklist nghiệm thu

### Web

- [ ] Nhãn/nút/thông báo nghiệp vụ đều tiếng Việt.
- [ ] Staff chỉ xem/sửa đúng bảo tàng được phân công; Admin có quyền tương ứng.
- [ ] Không tự tạo tầng; bảo tàng mặt bằng chung không bị bắt chọn tầng.
- [ ] Tải ảnh thật, đặt node/marker, nối node, lưu và tải lại giữ nguyên vị trí/liên kết.
- [ ] Kéo trực tiếp điểm; middle-drag pan; Ctrl+wheel zoom tại con trỏ; không tạo cạnh khi drag.
- [ ] Chọn hiện vật có sẵn từ DB; không tạo QR riêng cho tiện ích.
- [ ] Hai marker có thể liên kết chung node và cho cùng tuyến đến node đó.
- [ ] Xóa node xử lý cạnh và marker phụ thuộc; không xóa hiện vật DB.
- [ ] Cảnh báo chưa lưu, xung đột revision và lỗi API hiển thị rõ.
- [ ] Xem thử dùng bản nháp đã lưu, chỉ người có quyền quản lý truy cập.
- [ ] Publish mới đổi dữ liệu phía khách; unpublish ngừng cung cấp map.

### Flutter Visitor

- [ ] Dùng ảnh, marker và graph thật của snapshot published; không dùng draft hoặc dữ liệu mẫu.
- [ ] Bố cục mobile với map, tìm kiếm, bottom sheet, pinch/pan và nút vừa khung.
- [ ] Không có nút tạo/sửa/xóa điểm của staff.
- [ ] Quét QR hiện vật thật → scan API → đúng marker → đúng node xuất phát.
- [ ] Xin quyền camera và xử lý từ chối/hủy/đọc trùng/mất mạng trên thiết bị thật.
- [ ] QR ngoài hệ thống, hiện vật chưa gắn map, sai museum/map và nhiều marker được xử lý rõ.
- [ ] Chọn điểm đến bằng danh sách hoặc chạm map đều hiển thị đúng tuyến.
- [ ] Hai hiện vật cùng node, xuất phát trùng đích, đường một chiều, đường bị ngắt và lọc xe lăn hoạt động đúng.
- [ ] Không vẽ đoạn xuyên tường từ node đến marker; không gọi cost là mét.
- [ ] Đổi đích/quét lại không giữ tuyến cũ sai; camera được dừng khi đóng màn hình.
- [ ] Không tự di chuyển chấm vị trí khi chưa có cơ chế định vị liên tục.
- [ ] Visitor không đọc được draft dù tự sửa URL/tham số.

## 10. Kết quả cần bàn giao

Web editor và Flutter Visitor theo mô tả bố cục, thao tác ở trên; tích hợp API thật, bổ sung quét QR, kèm kiểm thử các luồng nghiệm thu. Ghi rõ phần còn chờ BE, tránh đánh dấu hoàn thành chỉ dựa trên mock data.

Camera QR và giao diện Flutter là phần FE cần triển khai. Các API còn thiếu phải được phối hợp với BE theo mục 7.3; chưa hỗ trợ tìm đường xuyên tầng.
