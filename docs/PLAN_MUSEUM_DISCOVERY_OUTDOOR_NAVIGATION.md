# KẾ HOẠCH TRIỂN KHAI KỸ THUẬT (IMPLEMENTATION PLAN)
## TÍNH NĂNG: MUSEUM DISCOVERY, LOCATION FILTERING & OUTDOOR NAVIGATION
**Dự án:** Smart Museum Guide System (SMGS)  
**Nền tảng:** Mobile Flutter (`smgs_mobile`) & Kết nối ASP.NET Core Web API  
**Căn cứ tài liệu:** [`Map.txt`](file:///d:/CAPSTONE/FrontEnd/Map.txt) & [`Museum_Discovery_API.md`](file:///d:/CAPSTONE/BackEnd/project-docs/Museum_Discovery_API.md)  
**Ngày lập:** 20/10/2026  
**Trạng thái:** Chờ xác nhận từ Nhóm / Tech Lead trước khi viết code  

---

## 1. TỔNG QUAN & PHẠM VI DỰ ÁN

### 1.1. Mục tiêu
Xây dựng trải nghiệm **Khám phá Bảo tàng & Dẫn đường Ngoài trời (Museum Discovery & Outdoor Navigation)** cho du khách (Visitor) trên ứng dụng Flutter:
1. Hiển thị bản đồ Google Maps cùng các điểm ghim (Marker) vị trí bảo tàng.
2. Tìm kiếm theo tên (`keyword`) và lọc theo Tỉnh/Thành phố (`cityCode` chuẩn 34 đơn vị hành chính mới).
3. Định vị GPS thiết bị ("Gần tôi") để tính khoảng cách đường thẳng Haversine và sắp xếp bảo tàng gần nhất lên đầu.
4. Xem trước tuyến đường đi đến bảo tàng (gọi Backend tích hợp Google Routes API) hiển thị polyline, quãng đường (km), thời gian (phút), phương tiện (`DRIVE`, `TWO_WHEELER`, `WALK`) và cảnh báo.
5. Nút mở ứng dụng Google Maps ngoài thiết bị để du khách bắt đầu dẫn đường chi tiết (Turn-by-turn).

### 1.2. Giới hạn phạm vi (Non-goals / Out of scope)
* **Không** tự code bộ dẫn đường turn-by-turn từng khúc cua trong Flutter (chuyển giao cho app Google Maps ngoài).
* **Không** GPS tracking liên tục chạy ngầm tốn pin.
* **Không** lưu lịch sử tọa độ di chuyển của du khách vào Database.
* **Không** xử lý Indoor Navigation giữa các hiện vật trong task này (đây là tính năng riêng).

---

## 2. ĐỐI CHIẾU HỢP ĐỒNG API (FRONTEND <-> BACKEND MAPPING)

Tất cả các API dưới đây đều yêu cầu Header: `Authorization: Bearer <accessToken>`.

### 2.1. API Danh mục Tỉnh/Thành phố
* **Endpoint:** `GET /api/museums/cities`
* **Mục đích:** Đổ dữ liệu vào Dropdown / BottomSheet bộ lọc tỉnh thành trên Mobile.
* **Dữ liệu trả về:**
  ```json
  {
    "statusCode": 200,
    "message": "Thành công",
    "data": [
      { "code": "79", "name": "Thành phố Hồ Chí Minh" },
      { "code": "01", "name": "Thành phố Hà Nội" },
      { "code": "48", "name": "Thành phố Đà Nẵng" }
    ]
  }
  ```
* **Lưu ý FE:** Dùng mã số 2 chữ số chuẩn (`79`, `01`), tuyệt đối không gửi `HCM` hay `HN`.

### 2.2. API Khám phá Bảo tàng (Search, Filter, Geolocation)
* **Endpoint:** `GET /api/museums`
* **Query Parameters:**
  * `keyword` (string, max 200 ký tự): Tìm kiếm theo tên (phân biệt dấu tiếng Việt).
  * `cityCode` (string, 2 ký tự): Mã tỉnh/thành.
  * `latitude`, `longitude` (double): Tọa độ du khách khi bấm "Gần tôi".
  * `sortBy` (`distance` | `newest`): Bắt buộc có tọa độ nếu chọn `distance`.
  * `page` (int, default 1), `pageSize` (int, default 20, max 50).
* **Dữ liệu trả về:**
  ```json
  {
    "statusCode": 200,
    "message": "Thành công",
    "data": {
      "items": [
        {
          "id": 1,
          "name": "Bảo tàng Lịch sử Quốc gia",
          "description": "Nơi lưu giữ các bảo vật...",
          "address": "Số 1 Tràng Tiền, Hoàn Kiếm, Hà Nội",
          "cityCode": "01",
          "latitude": 21.0253,
          "longitude": 105.8584,
          "distanceKm": 1.8,
          "openingHours": "08:00 - 17:00",
          "coverImageUrl": "https://...",
          "isActive": true,
          "createdAt": "2026-10-19T00:00:00Z"
        }
      ],
      "page": 1,
      "pageSize": 20,
      "totalCount": 1,
      "totalPages": 1
    }
  }
  ```
* **Lưu ý FE:**
  * Trường `id` ở Backend là kiểu số nguyên (`int`), cần map linh hoạt với model `Museum` hiện tại (có thể `id.toString()`).
  * Nếu không cấp quyền GPS: bỏ cả cặp tọa độ và không gửi `sortBy=distance`. `distanceKm` sẽ trả về `null`.
  * Marker chỉ vẽ khi `latitude` và `longitude` khác `null`.

### 2.3. API Xem trước Tuyến đường Ngoài trời (Outdoor Route Preview)
* **Endpoint:** `POST /api/navigation/outdoor/routes`
* **Request Body:**
  ```json
  {
    "museumId": 1,
    "origin": {
      "latitude": 10.7626,
      "longitude": 106.6824
    },
    "travelMode": "TWO_WHEELER"
  }
  ```
  *(Các chế độ `travelMode`: `DRIVE` - Ô tô, `TWO_WHEELER` - Xe máy, `WALK` - Đi bộ).*
* **Response Body:**
  ```json
  {
    "statusCode": 200,
    "message": "Thành công",
    "data": {
      "museumId": 1,
      "destination": {
        "latitude": 10.7769,
        "longitude": 106.7009
      },
      "travelMode": "TWO_WHEELER",
      "distanceMeters": 3500,
      "durationSeconds": 720,
      "encodedPolyline": "a~l~Fjk~uOw...~B",
      "warning": "Tuyến đi bộ và xe máy đang ở giai đoạn beta; có thể thiếu thông tin vỉa hè và lối đi."
    }
  }
  ```
* **Lưu ý FE:**
  * Đổi mét sang km: `(distanceMeters / 1000).toStringAsFixed(1) + ' km'`.
  * Đổi giây sang phút: `(durationSeconds / 60).round().toString() + ' phút'`.
  * Decode chuỗi `encodedPolyline` thành danh sách `LatLng` để vẽ `Polyline` lên Google Maps.
  * Bắt buộc hiển thị text `warning` nếu trường này khác `null` (theo chính sách Google API).

### 2.4. Mở Google Maps bên ngoài (Deep Link URL Scheme)
* Xử lý thuần phía Client bằng `url_launcher`:
  ```dart
  final url = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$lat,$lng',
    'travelmode': travelMode.toLowerCase(), // driving | bicycling | walking
    'dir_action': 'navigate',
  });
  await launchUrl(url, mode: LaunchMode.externalApplication);
  ```

---

## 3. CÁC THAY ĐỔI KIẾN TRÚC & DEPENDENCIES PHÍA MOBILE

### 3.1. Thêm Packages vào `pubspec.yaml`
```yaml
dependencies:
  google_maps_flutter: ^2.10.0      # Hiển thị bản đồ Google Maps & Marker, Polyline
  geolocator: ^13.0.2               # Xin quyền và lấy tọa độ GPS thiết bị du khách
  flutter_polyline_points: ^2.1.0   # Giải mã encodedPolyline thành danh sách điểm LatLng
  http: ^1.2.2                      # Gọi REST API Backend
```

### 3.2. Cấu hình Quyền (Permissions) Thiết bị
* **Android (`android/app/src/main/AndroidManifest.xml`):**
  ```xml
  <!-- Quyền truy cập vị trí -->
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.INTERNET" />

  <!-- Google Maps API Key -->
  <application>
      <meta-data
          android:name="com.google.android.geo.API_KEY"
          android:value="${GOOGLE_MAPS_API_KEY}" />
  </application>
  ```
* **iOS (`ios/Runner/Info.plist`):**
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>SMGS cần truy cập vị trí của bạn để tìm kiếm các bảo tàng gần nhất và chỉ dẫn lộ trình tham quan.</string>
  ```

### 3.3. Chiến lược "Graceful Degradation" (An toàn tuyệt đối khi chưa có Key)
* Để ứng dụng **không bao giờ bị crash/màn hình đen** nếu thiết bị thử nghiệm chưa cấu hình Google Maps API Key hoặc không có Google Play Services:
  * Kiểm tra tính khả dụng của Google Map Widget.
  * Tích hợp chế độ `Interactive Heritage Map Fallback`: Nếu Google Maps gặp lỗi khởi tạo hoặc mất mạng, tự động hiển thị sơ đồ bản đồ vector nghệ thuật phong cách Đông Sơn kèm danh sách Card bảo tàng tương tác mượt mà, vẫn đảm bảo 100% tính năng tìm kiếm, xem cự ly và nút bấm mở ứng dụng Google Maps ngoài.

---

## 4. KẾ HOẠCH TRIỂN KHAI THEO CÁC LÁT CẮT MỎNG (TASKS BREAKDOWN)

```
[Task 1: Setup & Data Layer]
        │
        ├── [Task 2: Geolocation & City Catalog Service]
        │
        ├── [Task 3: Museum Discovery Screen (Map + List + Filters)]
        │
        ├── [Task 4: Outdoor Route Preview Modal & Polyline Rendering]
        │
        ├── [Task 5: External Deep Link Navigation & Error Handling]
        │
        └── [Task 6: Verification, Performance & Heritage Theme Polish]
```

---

### Task 1: Bổ sung Dependencies, Model DTO & API Client
* **Mục tiêu:** Cài đặt các thư viện cần thiết, định nghĩa DTO khớp 100% với Backend (`MuseumDto`, `CityDto`, `RoutePreviewDto`), xây dựng `DiscoveryApiService`.
* **Chi tiết công việc:**
  1. Thêm `google_maps_flutter`, `geolocator`, `flutter_polyline_points`, `http` vào `pubspec.yaml`.
  2. Tạo Model `MuseumDiscoveryItem` hỗ trợ cả ID int và String, chứa `distanceKm`, `cityCode`, `coverImageUrl`.
  3. Tạo Model `CityItem` (`code`, `name`).
  4. Tạo Model `RoutePreviewResponse` (`distanceMeters`, `durationSeconds`, `encodedPolyline`, `warning`).
  5. Xây dựng `DiscoveryApiService` với các hàm `getMuseums()`, `getCities()`, `getOutdoorRoute()`, tích hợp cơ chế mock data dự phòng khi backend offline.
* **Tiêu chí nghiệm thu:**
  * Build project Flutter không lỗi syntax.
  * Unit test parse JSON của cả 3 API trả về object chuẩn xác.
* **File liên quan:**
  * `smgs_mobile/pubspec.yaml`
  * `smgs_mobile/lib/models/museum.dart`
  * `smgs_mobile/lib/models/city.dart`
  * `smgs_mobile/lib/models/outdoor_route.dart`
  * `smgs_mobile/lib/services/discovery_api_service.dart`

---

### Task 2: Service Định vị GPS & Quản lý Quyền Vị trí
* **Mục tiêu:** Xử lý xin quyền `ACCESS_FINE_LOCATION` và lấy tọa độ GPS du khách an toàn.
* **Chi tiết công việc:**
  1. Xây dựng `LocationService`: kiểm tra `isLocationServiceEnabled()`, xin quyền `requestPermission()`, lấy `getCurrentPosition()`.
  2. Xử lý kịch bản: Du khách từ chối quyền (Denied / DeniedForever) $\rightarrow$ hiển thị SnackBar hướng dẫn thân thiện và chuyển sang dùng bộ lọc Tỉnh/Thành phố thông thường, không để app bị đơ.
  3. Cấu hình permissions trong `AndroidManifest.xml` và `Info.plist`.
* **Tiêu chí nghiệm thu:**
  * Bấm nút "Gần tôi" xin quyền thành công và trả về `(lat, lng)`.
  * Khi từ chối quyền, app không crash, vẫn tìm kiếm và lọc bảo tàng bình thường.
* **File liên quan:**
  * `smgs_mobile/lib/services/location_service.dart`
  * `smgs_mobile/android/app/src/main/AndroidManifest.xml`
  * `smgs_mobile/ios/Runner/Info.plist`

---

### Task 3: Giao diện Màn hình Khám phá Bản đồ (Museum Discovery Screen)
* **Mục tiêu:** Xây dựng màn hình bản đồ tương tác hiển thị vị trí các bảo tàng, tích hợp bộ lọc và danh sách trượt.
* **Chi tiết công việc:**
  1. Màn hình chia bố cục 2 lớp (Map ở nền trên/toàn màn hình, Floating Search & Filter Bar ở trên đỉnh, Danh sách thẻ trượt ngang/dọc ở nửa dưới).
  2. Thanh tìm kiếm: Ô nhập `keyword` có debounce 400ms để không spam API.
  3. Bộ lọc Tỉnh/Thành phố: Nút bấm mở BottomSheet chọn tỉnh thành (lấy từ `/api/museums/cities`), mặc định hiển thị "Tất cả" hoặc vị trí hiện tại.
  4. Nút bấm nhanh "Gần tôi": Tự động kích hoạt GPS và gửi `sortBy=distance`.
  5. Vẽ các Marker bảo tàng lên bản đồ Google Maps với màu Burgundy đặc trưng (`#6B2E2E`), gắn icon di sản.
  6. Khi bấm Marker $\rightarrow$ cuộn đến thẻ bảo tàng tương ứng; khi vuốt thẻ $\rightarrow$ camera bản đồ tự lướt (`animateCamera`) đến bảo tàng đó.
* **Tiêu chí nghiệm thu:**
  * Tìm kiếm theo tên lọc đúng danh sách bảo tàng.
  * Chọn tỉnh "Hồ Chí Minh" (`79`) hoặc "Hà Nội" (`01`) lọc chính xác dữ liệu.
  * Marker tương tác 2 chiều mượt mà với danh sách thẻ.
* **File liên quan:**
  * `smgs_mobile/lib/screens/explore/museum_discovery_map_screen.dart`
  * `smgs_mobile/lib/widgets/museum_discovery_card.dart`
  * `smgs_mobile/lib/widgets/city_filter_sheet.dart`

---

### Task 4: Modal & Polyline Xem Trước Tuyến Đường (Route Preview)
* **Mục tiêu:** Gọi API Google Routes qua Backend và hiển thị tuyến đường đi trực quan trên bản đồ.
* **Chi tiết công việc:**
  1. Trên thẻ chi tiết bảo tàng, bổ sung nút **"Xem đường đi"**.
  2. Khi nhấn nút: lấy GPS hiện tại, hiển thị thanh chọn phương tiện:
     * Ô tô (`DRIVE`)
     * Xe máy (`TWO_WHEELER` - phổ biến nhất tại Việt Nam)
     * Đi bộ (`WALK`)
  3. Gửi request `POST /api/navigation/outdoor/routes`.
  4. Nhận response, giải mã `encodedPolyline` thành `List<LatLng>` và vẽ `Polyline` màu Hoàng Gia (`#B38B59`) hoặc Đỏ Mận (`#6B2E2E`) trên bản đồ.
  5. Tự động thu phóng camera (`LatLngBounds`) bao trọn cả điểm xuất phát và bảo tàng đích.
  6. Hiển thị Card tóm tắt lộ trình:
     * Cự ly: `3.5 km`
     * Thời gian ước tính: `12 phút`
     * Badge phương tiện đã chọn
     * Text cảnh báo an toàn màu vàng ấm (`warning`) nếu đi bộ/xe máy.
* **Tiêu chí nghiệm thu:**
  * Đường Polyline hiển thị rõ ràng, khớp mạng lưới đường bộ.
  * Camera tự căn chỉnh vừa vặn màn hình.
  * Đổi giữa Xe máy và Ô tô cập nhật đúng thời gian và cự ly.
* **File liên quan:**
  * `smgs_mobile/lib/widgets/route_preview_sheet.dart`
  * `smgs_mobile/lib/services/polyline_decoder.dart`

---

### Task 5: Tích hợp Nút "Chỉ đường bằng Google Maps" (Deep Link Navigation)
* **Mục tiêu:** Mở ứng dụng Google Maps chính thức của điện thoại để dẫn đường turn-by-turn bằng giọng nói.
* **Chi tiết công việc:**
  1. Bổ sung nút bấm nổi bật phong cách Heritage: **"Chỉ đường bằng Google Maps"** với biểu tượng điều hướng.
  2. Tạo deep link chuẩn `google.navigation:q=lat,lng&mode=d|w|b` hoặc fallback sang universal link `https://www.google.com/maps/dir/?api=1&destination=lat,lng&travelmode=...`.
  3. Kiểm tra `canLaunchUrl()` trước khi gọi `launchUrl(..., mode: LaunchMode.externalApplication)`.
  4. Fallback thông minh: Nếu máy không có app Google Maps, mở trình duyệt web hoặc Apple Maps (trên iOS).
* **Tiêu chí nghiệm thu:**
  * Bấm nút mở ngay ứng dụng Google Maps ngoài máy và sẵn sàng chế độ điều hướng.
  * Không làm ảnh hưởng hay crash app SMGS đang chạy ngầm.
* **File liên quan:**
  * `smgs_mobile/lib/screens/museum/museum_detail_screen.dart`
  * `smgs_mobile/lib/widgets/route_preview_sheet.dart`

---

### Task 6: Kiểm thử Hợp chuẩn, Tối ưu Hiệu năng & Hoàn thiện Heritage UI
* **Mục tiêu:** Đối chiếu toàn bộ 13 tiêu chí trong Mục 7 của `Map.txt` và đảm bảo tính thẩm mỹ cao cấp.
* **Chi tiết công việc:**
  1. Rà soát bảng màu đồng bộ: Nền Ngà Cổ (`#F4EBDD`), Đỏ Mận (`#6B2E2E`), Vàng Đồng Hoàng Gia (`#B38B59`), Chữ Than Gỗ (`#2E2521`).
  2. Tối ưu Marker caching để không giật lag khi kéo thả bản đồ.
  3. Kiểm tra các trường hợp biên:
     * Không có mạng (Offline mode).
     * Không cấp quyền GPS.
     * Bảo tàng chưa có tọa độ GPS.
     * Lỗi 401 token hết hạn hoặc 429 rate limit từ Backend.
  4. Chạy `flutter analyze` và `flutter test` đảm bảo 0 warning / 0 error.
* **Tiêu chí nghiệm thu:**
  * Đạt 13/13 tiêu chí Acceptance Criteria của `Map.txt`.
* **File liên quan:**
  * Toàn bộ các file trong module khám phá bản đồ.

---

## 5. BẢNG TIÊU CHÍ NGHIỆM THU (ACCEPTANCE CRITERIA CHECKLIST)

| STT | Tiêu chí nghiệm thu (Theo Mục 7 Map.txt) | Trạng thái dự kiến |
|:---:|---|:---:|
| 1 | Du khách xem được danh sách bảo tàng trên ứng dụng di động | ✅ Task 3 |
| 2 | Du khách xem được marker các bảo tàng trên Google Maps | ✅ Task 3 |
| 3 | Du khách tìm kiếm được bảo tàng theo tên (keyword) | ✅ Task 3 |
| 4 | Du khách lọc được bảo tàng theo tỉnh/thành phố (cityCode) | ✅ Task 3 |
| 5 | Du khách bấm "Gần tôi" và thấy danh sách sắp xếp theo khoảng cách tăng dần | ✅ Task 2, 3 |
| 6 | Xử lý đúng và êm thuận khi du khách từ chối cấp quyền GPS | ✅ Task 2 |
| 7 | Du khách chọn bảo tàng và xem trước được tuyến đường | ✅ Task 4 |
| 8 | Hiển thị quãng đường (km) và thời gian (phút) ước tính từ Google Routes API | ✅ Task 4 |
| 9 | Vẽ được đường Polyline tuyến đường rõ ràng trên bản đồ | ✅ Task 4 |
| 10 | Bấm nút mở được Google Maps bên ngoài để dẫn đường chi tiết | ✅ Task 5 |
| 11 | Không GPS tracking liên tục chạy ngầm | ✅ Đã kiểm soát |
| 12 | Không lưu lịch sử tọa độ GPS của du khách | ✅ Đã kiểm soát |
| 13 | Backend xử lý lỗi và không để lộ Google API Key ra client | ✅ Backend đã bảo đảm |

---

## 6. ĐỀ XUẤT BƯỚC TIẾP THEO

Kế hoạch kỹ thuật trên đã được lập hoàn chỉnh, bao quát toàn diện yêu cầu tại [`Map.txt`](file:///d:/CAPSTONE/FrontEnd/Map.txt) và khớp 100% với tài liệu kỹ thuật [`Museum_Discovery_API.md`](file:///d:/CAPSTONE/BackEnd/project-docs/Museum_Discovery_API.md) của Backend.

**Sau khi bạn xác nhận thông qua bản kế hoạch này, chúng ta sẽ bắt đầu ngay từ Task 1:**
* Cập nhật `pubspec.yaml` (thêm các packages bản đồ, định vị, HTTP).
* Tạo các Model DTO và `DiscoveryApiService` để kết nối dữ liệu.
