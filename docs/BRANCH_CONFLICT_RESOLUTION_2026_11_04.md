# Gỡ conflict khi chuyển từ main sang dev — 04/11/2026

## Nguyên nhân

Tại thời điểm xử lý, `dev` ở commit `bacd0d1` (fix map), còn `main` ở `db6354e` (remove mockdate). Hai nhánh cùng xuất phát từ `17f0a9d`, nhưng `dev` chưa có hai commit nối API và dọn mock:

- `f65f3a3`: Connect mobile and web apps to backend APIs.
- `db6354e`: remove mockdate.

Phần bổ sung kết nối API đang làm tiếp dựa trên nền `main`. Khi chuyển sang `dev`, Git gặp 20 tệp conflict, gồm cả những tệp dịch vụ API chưa tồn tại trên `dev` và bundle Flutter đã biên dịch. Chỉ chọn toàn bộ một phía sẽ làm mất chức năng hoặc thiếu các tệp phụ thuộc.

## Cách xử lý

- Khôi phục nền nối BE và dọn mock từ hai commit trên `main`, bao gồm service, context, model, UI và fixture chỉ dùng trong test.
- Giữ phần bổ sung API đang làm: quản lý tài khoản/phân công, ngân hàng câu hỏi, thương mại, nội dung, thống kê, chuyến tham quan và lịch sử Visitor. Chi tiết tại [FE_API_CONNECTIONS_2026_11_04.md](FE_API_CONNECTIONS_2026_11_04.md).
- Giữ nguyên ba tệp sửa bản đồ của `bacd0d1`: `museum_discovery_map_screen.dart`, `discovery_api_service.dart`, `route_preview_sheet.dart`. Giữ bộ lọc mới và xem trước tuyến đường theo địa điểm được chọn.
- Đồng bộ hai test tìm bộ lọc bản đồ từ nhãn cũ sang `Chỉ bảo tàng trong hệ thống`; giữ nguyên các kiểm tra GPS, phản hồi cũ, bộ lọc thành phố và phân trang.
- Giữ các dữ liệu hiện vật mẫu AI/3D đã được yêu cầu trước đó. Dữ liệu nghiệp vụ tiếp tục lấy từ BE; các mock bảo tàng/nghiệp vụ cũ không quay lại runtime.
- Các tệp JavaScript/font Flutter được tạo lại từ source đã ghép bằng `tools/update-visitor-web.ps1`, thay vì sửa trực tiếp mã biên dịch.
- Đánh dấu các tệp đã xử lý trong Git index. Không tạo commit hoặc push trong quá trình gỡ conflict.

Đã sao lưu nội dung trước khi xử lý và từng phiên bản của tệp conflict tại `D:\SEP409\tmp\fe-branch-conflict-20261104-123659`, ngoài repository FE.

## Kiểm tra

- React unit: 19 pass, 1 test tích hợp BE thật được skip.
- Playwright: 8/8 luồng UI pass với API giả lập trong test, không ghi DB thật.
- Flutter: 62 pass, 1 test tích hợp BE thật được skip.
- Flutter analyze: không có issue.
- React lint: exit 0; còn warning lint sẵn có, không phải lỗi build.
- Flutter web release và React production build: thành công. Bundle Visitor đã được tạo lại và đưa vào bản đóng gói portal.

Kiểm tra BE/DB thật vẫn cần môi trường BE hoạt động; các kết quả trên không thay thế việc kiểm thử tích hợp thực tế.

## Trước lần chuyển nhánh tiếp theo

Commit phần công việc đã kiểm tra trên nhánh hiện tại trước khi chuyển nhánh. Khi cần đưa một tính năng từ nhánh khác sang, merge/cherry-pick các commit phụ thuộc theo thứ tự; tránh mang riêng thay đổi mới sang nhánh chưa có nền API tương ứng.
