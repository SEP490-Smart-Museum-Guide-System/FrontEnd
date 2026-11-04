# Phát âm thanh thật cho Flutter Visitor — 04/11/2026

## Thay đổi

- Thay bộ đếm thời gian trong NarrationPlayer bằng audioplayers 6.8.1. Audio bytes thực sự được chuyển vào bộ giải mã/phát trên nền tảng; thời lượng và tiến độ lấy từ player.
- Phát, tạm dừng, tiếp tục, kéo tua, nghe lại và đổi tốc độ 0.75x/1x/1.25x. TTS tổng hợp ở 1x; tốc độ được đổi tại player, không tổng hợp lại mỗi lần đổi.
- Đóng player hoặc đổi văn bản/URL sẽ dừng và giải phóng nguồn audio. Phản hồi tải cũ không được tự khởi động player sau khi người dùng rời màn hình hoặc đổi nội dung.
- Với hiện vật có ID BE, màn Bản thuyết minh lấy nội dung từ `GET /api/artifacts/{id}/contents/published?languageCode=vi`, có token theo cơ chế hiện tại.
- Ưu tiên bản thu `audioUrl` đã xuất bản. Nếu chưa có bản thu, dùng `narrationText`, hoặc `description` của chính phiên bản published để gọi TTS. Không đọc câu placeholder trong danh mục thay cho bản thuyết minh thật.
- Nội dung không có bản published hiện lỗi/thử lại; không tự chuyển sang mẫu. Hiện vật demo AI/3D có ID mẫu vẫn dùng nội dung mẫu và được ghi chú riêng.
- Tải bản thu bằng HTTP trước khi phát để hỗ trợ media BE cần token; chỉ gửi token tới cùng origin với BE, không gửi sang storage bên ngoài.
- TTS trả thành công phải có header RIFF/WAVE hợp lệ trước khi đưa vào player. HTML hoặc phản hồi lỗi không được coi là audio; có thể thử lại. Cache TTS giới hạn 16 kết quả, phân biệt địa chỉ service/ngôn ngữ/tốc độ/văn bản.
- Flutter web mặc định gọi cùng origin qua `/ai-tts`, phù hợp proxy Vite đã có. Android vẫn dùng mặc định `10.0.2.2:8000`; có thể cấu hình `TTS_BASE_URL` khi build.
- Script `tools/update-visitor-web.ps1` nhận thêm `-TtsBaseUrl` để cấu hình địa chỉ service/proxy khi đóng gói.

Nguồn tham khảo API thư viện: [audioplayers](https://pub.dev/packages/audioplayers), [BytesSource](https://pub.dev/documentation/audioplayers/latest/audioplayers/BytesSource-class.html).

## Thử giọng đọc tại máy

Backend và PostgreSQL cần hoạt động để đăng nhập và đọc nội dung hiện vật đã xuất bản. Bật Docker Desktop trước, rồi chạy TTS:

```powershell
Set-Location "D:\SEP409\AI-System\TTS AI"
docker compose up -d --build
Invoke-RestMethod http://localhost:8000/health
```

Lần đầu service tải voice tiếng Việt và dữ liệu eSpeak vào volume; đợi health trả `status: ok`.

Chạy cổng web đã chứa bản Flutter Visitor:

```powershell
Set-Location D:\SEP409\FrontEnd\smgs_web
npm run dev -- --host 127.0.0.1 --port 8080
```

Mở `http://127.0.0.1:8080/visitor/`, đăng nhập Visitor, mở hiện vật → **Bản thuyết minh** → **Nghe thuyết minh âm thanh**. Có thể kiểm tra pause, tua, đổi tốc độ và đóng màn hình để dừng nghe.

Nếu TTS không chạy, UI báo chưa tải được âm thanh và cho thử lại. Có sẵn `audioUrl` hợp lệ thì phát bản thu đó, không cần gọi TTS.

## Đóng gói và triển khai

```powershell
Set-Location D:\SEP409\FrontEnd
.\tools\update-visitor-web.ps1 -Flutter C:\dev\flutter\bin\flutter.bat
Set-Location smgs_web
npm run build
```

Để chỉ định địa chỉ TTS/proxy thực tế, truyền thêm `-TtsBaseUrl https://dia-chi-thuc-te` vào script. Đây là base URL, chưa kèm `/api/v1/speech`.

Production cần proxy `/ai-tts` tới TTS service hoặc base URL HTTPS được phép CORS. Vite proxy chỉ chạy ở dev/preview, không tự trở thành cấu hình proxy Vercel. TTS service Python không thể được chạy bằng static bundle Flutter/React. Lần thay đổi này không bổ sung gateway BE hoặc triển khai TTS server mới.

Khi chạy trực tiếp `flutter run -d chrome`, web server Flutter không có Vite proxy; cần truyền `TTS_BASE_URL` trỏ tới proxy/service cho phép origin đó. Luồng kiểm tra được ưu tiên ở đây là `/visitor/` qua cổng Vite.

## Kiểm tra

- Flutter analyze: không có issue.
- Toàn bộ Flutter test: **68 pass, 1 test tích hợp BE thật skip**; có 6 test mới cho audio, published content, lỗi/retry và phản hồi cũ.
- Edge headless: **2 test pass**. Test dùng chính NarrationPlayer và plugin thật, cấp WAV PCM hợp lệ bằng HTTP fixture rồi kiểm tra HTMLMediaElement thực sự phát, currentTime tăng, pause giữ vị trí, rate đổi, kéo tua đổi vị trí, ended/nghe lại và đóng player xóa nguồn audio. Test lỗi TTS xác nhận không bắt đầu phát trước khi nhận được WAV hợp lệ.
- Flutter Visitor release và React production build thành công. Bundle tại Flutter build, public/visitor và dist/visitor có cùng hash; harness kiểm thử không được dùng làm entrypoint production.
- Browser test dùng WAV kiểm thử, không phải giọng Piper và không phải test inference AI. Không ghi DB thật.
- Tại thời điểm kiểm tra, Docker Linux Engine chưa chạy; Python hệ thống chưa có FastAPI/sherpa-onnx/uvicorn. Vì vậy chưa xác nhận tổng hợp giọng Piper trực tiếp trên máy trong lần này.

Chạy lại test Flutter:

```powershell
Set-Location D:\SEP409\FrontEnd\smgs_mobile
C:\dev\flutter\bin\flutter.bat analyze
C:\dev\flutter\bin\flutter.bat test
```

Chạy kiểm tra audio thật trên browser:

```powershell
Set-Location D:\SEP409\FrontEnd\smgs_mobile
C:\dev\flutter\bin\flutter.bat build web --release --base-href / --target test/browser/audio_harness.dart --output build/audio_harness
Set-Location ..\smgs_web
npx playwright test --config playwright.audio.config.js
```

Harness chỉ dùng trong kiểm thử, không thay entrypoint `lib/main.dart` của ứng dụng. Nội dung mẫu AI, sinh nội dung/chat và luồng 3D không được thay đổi trong lần này.
