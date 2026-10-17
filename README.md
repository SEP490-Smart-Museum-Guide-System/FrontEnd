# SMGS · Smart Museum Guide System — Frontend

Frontend của **Smart Museum Guide System (SMGS)**. Dự án hỗ trợ hành trình tham quan bảo tàng, quản trị nội dung di sản và vận hành hệ thống. Toàn bộ dữ liệu hiện là **mô phỏng ở phía giao diện**; backend, xác thực thật, thanh toán thật và đồng bộ liên portal sẽ được kết nối ở giai đoạn sau.

## Thành phần dự án

| Thư mục | Công nghệ | Người dùng | Mục đích |
| --- | --- | --- | --- |
| [`smgs_mobile`](./smgs_mobile) | Flutter | Khách tham quan | Tra cứu bảo tàng, khám phá hiện vật, quét QR, AI Guide, tour, quiz và chỉ đường Google Maps. |
| [`smgs_web`](./smgs_web) | React + Vite | Quản trị viên, Nhân viên bảo tàng, Giám tuyển, Nhân viên hệ thống | Cổng nghiệp vụ duy nhất để quản lý, thẩm định và vận hành hệ thống. |

## Vai trò và ranh giới quyền hạn

| Vai trò | Kênh sử dụng | Nghiệp vụ chính |
| --- | --- | --- |
| **Khách tham quan** | Flutter mobile / Flutter Web xem thử | Tìm bảo tàng, quét QR, xem hiện vật, AI Guide, tour, quiz, lịch sử, phản hồi, mua nội dung nâng cao và mở Google Maps chỉ đường. |
| **Nhân viên bảo tàng** | `smgs_web` | Quản lý bảo tàng, hiện vật, media, QR, vị trí trên bản đồ, tour và nội dung AI; đệ trình nội dung để Giám tuyển thẩm định. |
| **Giám tuyển** | `smgs_web` | Hiệu đính, yêu cầu sửa, từ chối, phê duyệt và xuất bản thông tin hiện vật, bản dịch, narration và quiz AI của bảo tàng được phân công. |
| **Nhân viên hệ thống** | `smgs_web` | Hỗ trợ khách, xử lý khiếu nại/hoàn tiền, đối soát giao dịch, kiểm duyệt phản hồi, giám sát lỗi vận hành và chất lượng AI. |
| **Quản trị viên** | `smgs_web` | Quản lý tài khoản/RBAC, bảo tàng, cấu hình hệ thống, giao dịch, nhật ký và danh sách bảo tàng hiển thị trên Google Maps. |

Luồng kiểm duyệt nội dung: **Nhân viên bảo tàng đệ trình → Giám tuyển thẩm định trong cùng portal web → phản hồi hoặc xuất bản → Khách tham quan sử dụng nội dung đã xuất bản**.

## Tài khoản mô phỏng

Mật khẩu chung cho các tài khoản là `smgs123`.

| Vai trò | Email | Portal |
| --- | --- | --- |
| Quản trị viên | `admin@smgs.vn` | `smgs_web` |
| Nhân viên bảo tàng | `staff@smgs.vn` | `smgs_web` |
| Nhân viên hệ thống | `system@smgs.vn` | `smgs_web` |
| Giám tuyển | `curator@smgs.vn` | `smgs_web` |
| Khách tham quan | `khach@smgs.vn` | `smgs_mobile` hoặc `/visitor/` khi xem thử trên web |

## Yêu cầu môi trường

- Node.js 20+ và npm cho portal React.
- Flutter SDK 3.13+ và Chrome cho ứng dụng Khách tham quan.

## Chạy cục bộ

### 1. Cổng nghiệp vụ web

```powershell
cd D:\SEP409\FrontEnd\smgs_web
npm install
npm run dev -- --host 127.0.0.1 --port 8090
```

Mở `http://127.0.0.1:8090`.

### 2. Ứng dụng Khách tham quan khi chưa có simulator

```powershell
cd D:\SEP409\FrontEnd\smgs_mobile
flutter pub get
flutter run -d chrome
```

## Kiểm tra trước khi bàn giao

```powershell
# Portal nghiệp vụ
cd D:\SEP409\FrontEnd\smgs_web
npm run build
npm run lint

# Ứng dụng Khách tham quan
cd D:\SEP409\FrontEnd\smgs_mobile
flutter analyze
flutter test test/main_flows_test.dart
```

## Google Maps và mô hình 3D

- Khách tham quan mở chỉ đường qua Google Maps deep link. Chỉ các bảo tàng được Admin bật `googleMapsVisible` mới xuất hiện công khai.
- Hiện vật 3D dùng định dạng `.glb`; model mẫu nằm tại [`trong_ong_ong_son_-_viet_nam.glb`](./trong_ong_ong_son_-_viet_nam.glb).
- Tài liệu chi tiết về phạm vi mô phỏng Google Maps: [`GOOGLE_MAPS_MO_PHONG.md`](./GOOGLE_MAPS_MO_PHONG.md).

## Schema backend và hợp đồng dữ liệu

FE đối chiếu với schema PostgreSQL tại `../BackEnd/project-docs/smgs_schema.dbml`. Mapping role, bảng và luồng API dự kiến nằm trong [`DBML_FE_MAPPING.md`](./DBML_FE_MAPPING.md).

## Deploy Vercel

### Portal nghiệp vụ và bản xem Flutter Web

Vercel Project hiện tại dùng cấu hình gốc [`vercel.json`](./vercel.json), build `smgs_web` và xuất bản từ `smgs_web/dist`. Bản Flutter Web xem thử của Khách tham quan được phục vụ tại đường dẫn `/visitor/`.

Giám tuyển đăng nhập trên chính portal này bằng `curator@smgs.vn`. Khi có backend, API xác thực/RBAC phải trả về `museumId` để chỉ hiển thị các nội dung thuộc bảo tàng được phân công.

## Cấu trúc dữ liệu hiện tại

- Dữ liệu mẫu của portal nghiệp vụ: [`smgs_web/src/data/mockData.js`](./smgs_web/src/data/mockData.js).
- Trạng thái/logic mô phỏng của portal nghiệp vụ: [`smgs_web/src/context/AppContext.jsx`](./smgs_web/src/context/AppContext.jsx).
- Dữ liệu mô phỏng hiện chỉ lưu trong bộ nhớ phiên hoặc `localStorage`/`sessionStorage`; tải lại trang có thể khôi phục dữ liệu mẫu.

## Giới hạn hiện tại

- Chưa có backend và cơ sở dữ liệu, vì vậy dữ liệu giữa `smgs_web` và `smgs_mobile` chưa đồng bộ thật.
- Đăng nhập, thanh toán, hoàn tiền, AI và phê duyệt chỉ là luồng UI mô phỏng.
- Google Maps hiện mở chỉ đường bằng URL, chưa nhúng SDK bản đồ tương tác hoặc Places API.
