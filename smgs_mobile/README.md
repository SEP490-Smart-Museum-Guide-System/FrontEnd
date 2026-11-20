# SMGS · Ứng dụng khách tham quan

Ứng dụng Flutter này dành cho **Visitor (Khách tham quan)**. Ba vai trò còn lại của hệ thống — Admin, Museum Staff và System Staff — sử dụng cổng React + Vite tại `../smgs_web`.

Ứng dụng đã có các luồng gọi backend cho đăng nhập và dữ liệu nghiệp vụ. Khách dùng tài khoản được tạo trên backend; không coi các tài khoản/dữ liệu mô phỏng trong tài liệu cũ là tài khoản production.

## Chạy trên web khi chưa có simulator

```powershell
cd D:\SEP409\FrontEnd\smgs_mobile
flutter pub get
flutter run -d chrome
```

Kiểm tra bằng `flutter analyze` và `flutter test test/main_flows_test.dart`.

## Định vị tự động khi mở app

App tự xin quyền vị trí ở lần mở đầu tiên và theo dõi trong lúc đang sử dụng, xuyên suốt các tab/màn hình. Chấp nhận quyền **Chỉ khi dùng ứng dụng** là đủ. Khi ra nền app tạm dừng; quay về app tự kiểm tra quyền/GPS và tiếp tục. Không tự mở lại hộp thoại quyền sau khi khách từ chối; thẻ vị trí trên Trang chủ dẫn tới Cài đặt để cấp lại. Đây không phải dịch vụ theo dõi nền với quyền **Luôn cho phép**.

Trang chủ tự nhận biết bảo tàng từ tọa độ trong dữ liệu backend và thông báo **Đã đến khu vực … (GPS)** sau ít nhất hai mẫu hợp lệ cách nhau 10 giây. Mẫu phải mới trong 30 giây, sai số tối đa 50 m, không phải vị trí giả lập/cache; khoảng cách cộng sai số phải nằm trong bán kính 150 m của đúng một bảo tàng. Nếu nhiều bảo tàng cùng vùng, app không tự chọn nhầm. Đây là ước tính khu vực, không tự tạo lượt tham quan hoặc ghi nhận phòng/tầng. QR tại cổng/phòng vẫn cung cấp điểm neo chính xác cho sơ đồ trong nhà. Bản đồ đường đi cập nhật chấm GPS; tuyến OSRM vẫn là tuyến được tính khi mở.

Kiểm thử: `flutter test test/automatic_location_test.dart test/museum_presence_test.dart`. Kiểm tra thực địa trên điện thoại thật để đánh giá sai số tại từng bảo tàng; test mô phỏng không chứng minh độ chính xác GPS trong nhà.

## Build APK trên GitHub Actions (main)

Mở **Actions → Android APK → Run workflow → main**. APK cũng tự build khi code mobile hoặc workflow được push lên main. Sau khi job thành công, tải **Artifacts → smgs-android-apk-<run number>**, giải nén rồi cài file `.apk`. Artifact có thêm SHA-256 và được giữ 14 ngày.

Workflow mặc định dùng URL gốc `https://smgs-web.vercel.app`, nơi `/api/museums` đã được kiểm tra trả JSON từ API ngày 20/11/2026. App tự thêm `/api`. Có thể đổi bằng input `api_base_url` khi chạy thủ công hoặc repository variable `MOBILE_API_BASE_URL` trong **Settings → Secrets and variables → Actions → Variables**. Không dùng `10.0.2.2` cho điện thoại thật.

TTS/Vision là dịch vụ riêng: cấu hình input `tts_base_url`/`vision_base_url` hoặc variable `MOBILE_TTS_BASE_URL`/`MOBILE_VISION_BASE_URL` khi đã deploy chúng. Nếu bỏ trống, app giữ default hiện có; APK build thành công không chứng minh các dịch vụ AI đang hoạt động. Hai đường dẫn `/ai-tts/health` và `/ai-vision/health` trên domain web hiện trả 404 tại lần kiểm tra này. Không đưa service key bí mật vào URL/defines của APK.

SDK: Flutter **3.47.4**, Java **17**. Workflow chạy test rồi `flutter build apk --release` và upload APK universal để cài demo. Gradle hiện ký release bằng debug signing; đây không phải bản ký phát hành Play Store. Các runner có thể dùng debug key khác nhau giữa các lần build, nên Android có thể yêu cầu gỡ bản demo cũ trước khi cài bản mới nếu chữ ký không khớp. Dữ liệu local của app có thể mất khi gỡ.

Workflow source: `.github/workflows/android-apk.yml`. URL được truyền qua file JSON, không được thực thi như shell command. Không phát hành APK từ pull request.
