# Hoàn thiện kết nối FE với các API BE đã có — 04/11/2026

## Phạm vi

Nối các luồng nghiệp vụ còn thiếu trong bản audit API vào React web và Flutter Visitor. Không bổ sung endpoint BE mới, không tạo dữ liệu giả trong ứng dụng và không ghi dữ liệu lên DB thật trong quá trình kiểm thử. Các hiện vật mẫu AI/3D vẫn giữ riêng theo yêu cầu trước đó.

## Web — Admin / Museum Staff / Curator / System Staff

| Vị trí trên UI | Chức năng đã nối |
| --- | --- |
| Người dùng & phân quyền | Đọc danh sách role từ BE; tạo, xem chi tiết, sửa thông tin/mật khẩu; đổi role riêng; khóa/mở khóa; thêm/thu hồi phân công theo bảo tàng/phòng/hiện vật; danh sách phân công toàn hệ thống có bộ lọc. |
| Chủ đề hiện vật | Tạo, sửa, ẩn/xóa chủ đề; xem và lưu danh sách chủ đề của hiện vật; gỡ từng chủ đề. |
| Ngân hàng câu hỏi | Tiếp nhận gợi ý quiz từ Xưởng AI để hiệu đính/lưu từng câu; tạo/sửa câu hỏi với 2–6 đáp án và đúng một đáp án đúng; Curator/Admin thẩm định; tạo bộ câu hỏi từ câu đã duyệt; xuất bản bộ câu hỏi theo quyền BE. |
| Huy hiệu khám phá | Đọc định nghĩa huy hiệu và tạo mốc quét hiện vật/trả lời đúng; đọc đúng RuleJson do BE lưu. |
| Dịch vụ & giao dịch | Tạo/sửa resource free/premium và gói dịch vụ; chọn resource theo ID; cấu hình số người, giá, loại tiền và thời hạn. |
| Chi tiết đơn & đối soát | Đọc chi tiết đơn, các lần thanh toán và hóa đơn; xác nhận thành công/thất bại theo chứng từ; thu hồi pass theo mã quyền khách cung cấp. |
| Báo cáo doanh thu | Gọi API revenue theo khoảng UTC, hiển thị riêng từng loại tiền. Dashboard lấy doanh thu tháng từ API này, không cộng lẫn các loại tiền. |
| Bản đồ trong bảo tàng → Quản lý tòa nhà, tầng & phòng | Tạo/sửa/xóa tòa nhà, tầng và phòng bằng các endpoint có sẵn. BE quyết định có cho xóa bản ghi đang được tham chiếu hay không. |
| Chi tiết hiện vật → Nội dung | Xem các bản đã xuất bản và lịch sử phiên bản; soạn nội dung tiếng Việt/narration/audio URL rồi gửi kiểm duyệt bằng endpoint manual. |
| Chi tiết hiện vật → Cấu hình mô hình 3D | Lưu tên, poster, góc camera, góc nhìn, tỷ lệ và tự xoay qua API settings. |
| Hỗ trợ & khiếu nại | Mở hồ sơ bằng endpoint chi tiết; giữ thao tác tiếp nhận/xử lý đã nối trước đó. |

Menu tuân theo role. Admin chọn bảo tàng khi quản lý chủ đề/câu hỏi/giao dịch. Curator có UI thẩm định quiz và tra cứu hiện vật; không hiển thị nút sửa/xóa hiện vật như Museum Staff. API vẫn là nơi quyết định quyền truy cập cuối cùng.

Tài khoản đổi role cần đăng nhập lại để nhận JWT mới. UI lưu thông tin, role và phân công theo từng thao tác, không báo thành công chung khi một bước còn lỗi.

## Flutter Visitor — có thể xem bằng web

| Luồng | Chức năng đã nối |
| --- | --- |
| Quét QR | Đọc nội dung và POST recognitions/qr với visitId tùy chọn và RequestId UUID. Khi thử lại cùng yêu cầu, giữ UUID để chống ghi trùng. GET tra cứu QR cũng gửi token để BE kiểm tra nội dung premium đã mua. |
| Chọn chuyến để quét | Tải danh sách chuyến đang tham quan, chọn chuyến hoặc quét độc lập. Không dùng ID bảo tàng làm ID chuyến hoặc ID sơ đồ. |
| Tuyến đã xuất bản | Đọc danh sách và chi tiết tour, bắt đầu visit với tourId thật; tiến độ lấy từ BE. |
| Tiến độ & dẫn đường | Đọc visit/progress và visitor-navigation/location/route. Mở sơ đồ đã xuất bản theo mã do bảo tàng cung cấp, hiển thị tuyến node BE trả về; kiểm tra revision và bỏ phản hồi cũ khi đổi sơ đồ/đích. |
| Lịch sử thử tài | GET quiz-attempts/me và chi tiết theo ID; tiếp tục bài đang làm, cập nhật kết quả, yêu cầu lượt mới bằng reset theo quy tắc BE. |
| Sổ điểm, huy hiệu | Đọc sổ giao dịch điểm; ghép tên huy hiệu từ danh mục với huy hiệu tài khoản. |
| Chi tiết đơn mua | Đọc lại đơn của khách, các lần thanh toán và hóa đơn khi đã trả tiền; không tự cấp quyền từ kết quả gửi yêu cầu thanh toán. |
| Vé nhóm | Người mua gói nhiều người tạo mã nhóm; thành viên nhập mã để nhận pass. Tạo mã mới có xác nhận vì BE thay thế mã cũ. |
| Quyền truy cập | Hiển thị mã pass để hỗ trợ tra cứu/thu hồi; đọc nội dung gói và kiểm tra access theo resource. |
| Đánh giá | Đọc feedback theo visit, sửa qua PUT nếu BE cho phép; hiển thị hết hạn chỉnh sửa và phản hồi nhân viên. Giữ các điểm đánh giá chi tiết đã có khi sửa nhận xét tổng thể. |
| Khiếu nại | Mở chi tiết yêu cầu bằng complaints/me/{id} và cập nhật trạng thái xử lý. |
| Chi tiết bảo tàng | Tải lại thông tin qua endpoint chi tiết, có trạng thái lỗi/thử lại. |

Quét độc lập vẫn có thể mở quiz/tích điểm nếu đủ điều kiện BE; quét gắn visit mới cập nhật tiến độ của chuyến đó. Chỉ ghi nhận sau POST thành công. Quiz chỉ có khi đã được xuất bản và BE đã cấp cho Visitor.

Dẫn đường theo visit dùng vị trí quét gần nhất, không phải định vị liên tục. BE hiện chỉ dẫn được giữa hai hiện vật có marker duy nhất trên cùng sơ đồ đã xuất bản. Chưa có API liệt kê sơ đồ public theo bảo tàng, vì vậy UI yêu cầu mã sơ đồ thực tế; không tạo sơ đồ hoặc tuyến đường giả.

## Phân trang và trạng thái lỗi

- API có envelope items/totalPages được đọc theo metadata.
- Những API trả mảng nhưng có tham số phân trang (tour, câu hỏi, orders/passes, lịch sử quiz/QR/điểm) được đọc tiếp cho đủ trang.
- API mảng không phân trang (resources, products, roles, định nghĩa huy hiệu) chỉ gọi một lần, kể cả có đúng 50 bản ghi.
- Form giữ dữ liệu khi API từ chối; nút gửi có khóa khi đang lưu. Dữ liệu chỉ cập nhật sau phản hồi thành công.
- Khi đổi phạm vi, kết quả cũ không được hiển thị cho phạm vi mới. Bookmark và mẫu AI vẫn được phân biệt với dữ liệu tài khoản do BE lưu.

## API thay thế không cần tạo luồng trùng lặp

Các route tương đương vẫn có thể không được gọi riêng: POST topics so với POST museums/{id}/topics, POST gán thêm topic so với PUT toàn danh sách, PUT status so với PATCH status, GET topic theo ID khi danh sách đã trả đủ dữ liệu. Chức năng tương ứng đã có UI và endpoint chính.

GET artifacts/{id}/viewer và viewer-ui là lựa chọn trình chiếu tổng hợp/trang viewer của BE. FE đang sử dụng viewer riêng và các API media/model/nội dung; không đổi sang trang viewer debug chỉ để tăng số endpoint được gọi.

## Phần vẫn chưa thể nối

- Refund, audit, sự cố/chất lượng AI, chatbot/RAG và tour AI cá nhân hóa chưa có API nghiệp vụ tương ứng trong repo đã đối chiếu.
- System Staff chưa được BE cấp quyền commerce, nên chưa bật chức năng đối soát cho role này. Xác nhận giao dịch hiện dành cho Admin/Museum Staff.
- Xác nhận thanh toán hiện là đối soát của người có quyền; không đồng nghĩa đã tích hợp cổng thanh toán/webhook thật.
- BE chưa có danh sách pass của một đơn cho người quản lý: thao tác thu hồi yêu cầu mã pass thực tế khách cung cấp, không tự suy ra pass từ mã đơn.

## Kiểm tra

- Node: 19 ca đạt, 1 ca auth live bỏ qua khi chưa cấu hình môi trường.
- Playwright: 8 ca đạt trên trình duyệt: tài khoản/lỗi API/role/phân công, Curator duyệt và xuất bản quiz, Museum Staff tạo đáp án, cấu hình dịch vụ/đối soát/doanh thu, chủ đề hiện vật, phòng trưng bày và RuleJson huy hiệu; kiểm tra gợi ý quiz AI đi vào ngân hàng câu hỏi thay vì nội dung hiện vật.
- Flutter: 62 ca đạt, 1 ca auth live bỏ qua; kiểm thử toàn bộ widget/service, chống trùng QR, ID tour/visit thật, phân trang lịch sử, tham số route, lỗi nhập mã nhóm, PUT feedback, UI quét QR, gửi token khi tra cứu nội dung premium, feedback chỉ đọc và layout 320px/chữ lớn.
- Flutter analyze không có vấn đề. React và Flutter web đã build thành công; bundle Visitor trong public và dist khớp với kết quả build Dart. React lint còn cảnh báo ở các component/hook và bundle có cảnh báo kích thước, không có lỗi build chặn.
- Các API test được giả lập ở thư mục test/e2e, không được import vào sản phẩm.
- Đã thử kiểm tra chỉ đọc http://127.0.0.1:5169; BE local từ chối kết nối tại thời điểm kiểm tra. Chưa chạy end-to-end với DB thật và chưa deploy/push.

Lệnh kiểm tra:

```powershell
cd D:\SEP409\FrontEnd\smgs_web
npm test
npm run test:e2e
npm run build
npm run lint

cd D:\SEP409\FrontEnd\smgs_mobile
flutter test --no-pub
flutter analyze --no-pub

cd D:\SEP409\FrontEnd
.\tools\update-visitor-web.ps1 -Flutter C:\dev\flutter\bin\flutter.bat
cd smgs_web
npm run build
```

Playwright dùng Edge sẵn có trên Windows; môi trường khác cần cài browser bằng `npx playwright install chromium` hoặc chọn browser bằng biến PLAYWRIGHT_CHANNEL.

React dùng VITE_API_BASE_URL (thường gồm hậu tố /api). Flutter dùng API_BASE_URL là địa chỉ gốc BE. Khi chuẩn bị bundle Flutter cho BE ở địa chỉ khác, chạy script với `-ApiBaseUrl <địa-chỉ-BE>`; script chấp nhận cả địa chỉ có hậu tố /api và chuẩn hóa trước khi build. Không tự đoán địa chỉ BE production.

Bản Vercel hiện đóng gói `smgs_web/public/visitor`, nên phải cập nhật bundle Flutter bằng script trước khi build React. Các file test output/log/build tạm đã được ignore; bundle Visitor được giữ theo cơ chế deploy hiện có của repo.
