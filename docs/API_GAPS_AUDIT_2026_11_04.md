# Đối chiếu API BE và FE — 04/11/2026

> Đây là trạng thái trước đợt nối API. Các luồng đã triển khai tiếp được ghi trong [FE_API_CONNECTIONS_2026_11_04.md](FE_API_CONNECTIONS_2026_11_04.md); không dùng danh sách “chưa nối” bên dưới làm trạng thái sau triển khai.

## Phạm vi và cách hiểu

Đối chiếu controller, service, đăng ký dependency của BE .NET, lời gọi trong React `smgs_web/src` và Flutter `smgs_mobile/lib`. Kiểm tra thêm các route trong `AI-System`. Không tính file build, test hoặc chỉ định nghĩa wrapper chưa có màn hình gọi là đã tích hợp. Đây là rà mã nguồn tại máy, chưa kiểm chứng deployment hoặc chạy từng endpoint với DB thật.

- **BE có, FE chưa dùng:** đã có endpoint và phần xử lý; FE cần nối luồng phù hợp.
- **BE chưa có API nghiệp vụ:** chưa tìm thấy route/service tương ứng trong mã nguồn hiện tại. Có bảng trong DBML hoặc nút trên UI không có nghĩa đã code API.
- **Thiếu quyền hoặc thiếu tích hợp:** đã có một phần, cần bổ sung; không gọi là chưa code toàn bộ.

Tất cả đường dẫn dưới đây bắt đầu bằng `/api`. `{id}` đại diện ID theo route thực tế (int, long hoặc UUID).

## 1. BE đã có, FE chưa dùng

### 1.1. Ngân hàng câu hỏi và xuất bản quiz

FE hiện gọi quiz hằng ngày và trả lời câu hỏi, nhưng chưa có màn quản lý ngân hàng câu hỏi sử dụng các API sau:

- `GET /question-bank/questions?artifactId=...`
- `POST /question-bank/questions?artifactId=...`
- `PUT /question-bank/questions/{id}`
- `POST /question-bank/questions/{id}/review`
- `GET /question-bank/quizzes?artifactId=...`
- `POST /question-bank/quizzes?artifactId=...`
- `POST /question-bank/quizzes/{id}/publish`

Museum Staff tạo/chỉnh sửa, Curator/Admin kiểm duyệt và xuất bản theo quyền BE. Kết quả quiz dạng văn bản trong Xưởng AI chưa thay thế việc lưu câu hỏi/options/quiz qua các endpoint này.

### 1.2. Ghi nhận quét và lịch sử nhận diện

- `POST /recognitions/qr`
- `GET /recognitions/me`

Flutter hiện dùng `GET /artifacts/scan/{qrCode}` để đọc nội dung. Chưa gọi POST ghi nhận lịch sử. Trong `RecognitionService`, POST mới là luồng ghi tiến độ theo visit, mở daily quiz, cộng điểm và xét huy hiệu trong transaction. Vì vậy mở được nội dung từ QR chưa đủ để các chức năng đó cập nhật.

### 1.3. Tiến độ và dẫn đường Visitor

- `GET /visits/{visitId}/progress`
- `GET /visitor-navigation/location?visitId=...`
- `GET /visitor-navigation/route?visitId=...&mapId=...&artifactId=...`

FE có chức năng sơ đồ đã xuất bản và tính tuyến cục bộ, nhưng chưa nối ba endpoint theo lượt tham quan này. Phần mở/tạo/kết thúc lượt tham quan đã gọi API riêng, không liệt kê là thiếu toàn bộ.

### 1.4. Lịch sử quiz và sổ điểm

- `GET /quiz-attempts/me`
- `GET /quiz-attempts/{id}`
- `POST /quiz-attempts/{id}/reset`
- `GET /gamification/me/transactions`
- `GET /gamification/badges`
- `POST /gamification/badges`

Flutter đã gọi `GET /daily-quizzes/today`, POST bắt đầu/trả lời, `gamification/me/points` và `gamification/me/badges`. Chưa có luồng xem lịch sử làm bài, xem lại kết quả bằng ID, reset lượt làm, sổ điểm và quản lý định nghĩa huy hiệu. Reset tuân theo quy tắc BE, không mặc định mọi lượt đã hoàn thành đều reset được.

### 1.5. Cấu hình thương mại

- `GET /commerce/museums/{museumId}/resources`
- `POST /commerce/museums/{museumId}/resources`
- `PUT /commerce/museums/{museumId}/resources/{id}`
- `POST /commerce/museums/{museumId}/products`
- `PUT /commerce/museums/{museumId}/products/{id}`
- `GET /commerce/resources/{resourceId}/access`

FE đã đọc danh sách sản phẩm/manage products, nhưng chưa có form cấu hình resource/sản phẩm và lời gọi kiểm tra access trực tiếp. BE còn kiểm tra quyền đọc ở một số API nội dung; việc chưa gọi endpoint access không đồng nghĩa BE hoàn toàn chưa chặn premium.

### 1.6. Xử lý thanh toán, đơn hàng, vé nhóm và doanh thu

- `GET /commerce/orders/{orderId}/manage`
- `GET /commerce/orders/{orderId}/transactions`
- `POST /commerce/payments/{attemptId}/confirm`
- `POST /commerce/orders/{orderId}/group-key`
- `POST /commerce/passes/redeem`
- `POST /commerce/passes/{passId}/revoke`
- `GET /commerce/orders/{orderId}/invoice`
- `GET /commerce/museums/{museumId}/revenue?from=...&to=...`

FE đã tạo đơn, tạo yêu cầu thanh toán, xem đơn và pass. Chưa có UI xác nhận thanh toán cho người có quyền, chi tiết giao dịch, mã nhóm/nhập mã, thu hồi quyền, hóa đơn và báo cáo doanh thu theo khoảng thời gian. Dashboard đang cộng số tiền từ danh sách đơn, chưa dùng endpoint revenue.

### 1.7. Quản trị tài khoản và phân công

- `GET /admin/roles`
- `GET /admin/accounts/{id}`
- `PUT /admin/accounts/{id}`
- `PUT /admin/accounts/{id}/roles`
- `GET /admin/accounts/{id}/assignments`
- `POST /admin/accounts/{id}/assignments`
- `DELETE /admin/accounts/{id}/assignments/{assignmentId}`
- `GET /admin/assignments`
- `DELETE /admin/assignments/{assignmentId}`

FE hiện gọi danh sách/tạo tài khoản và đổi trạng thái hoạt động. Phân công Museum Staff qua `POST /museums/{museumId}/indoor-staff` đã được dùng ở màn bản đồ; đó không phải toàn bộ luồng phân công chi tiết cho Museum Staff/Curator theo bảo tàng/phòng/hiện vật.

### 1.8. Chủ đề hiện vật

Toàn bộ API quản lý chủ đề chưa được FE nối:

- `GET /topics`, `GET /topics/{id}`
- `GET /museums/{museumId}/topics`
- `POST /topics`, `POST /museums/{museumId}/topics`
- `PUT /topics/{id}`, `DELETE /topics/{id}`
- `GET /artifacts/{artifactId}/topics`
- `POST /artifacts/{artifactId}/topics`
- `PUT /artifacts/{artifactId}/topics`
- `DELETE /artifacts/{artifactId}/topics/{topicId}`

Adapter có đọc trường topics đi kèm hiện vật, nhưng chưa có màn CRUD/gán chủ đề gọi các route trên.

### 1.9. Cấu trúc không gian

BE đã có nhưng chưa thấy thao tác UI gọi:

- `PUT`, `DELETE /museums/{museumId}/buildings/{buildingId}`
- `PUT`, `DELETE /museums/{museumId}/floors/{floorId}`
- `POST /museums/{museumId}/galleries`
- `PUT`, `DELETE /museums/{museumId}/galleries/{galleryId}`

FE đã gọi tạo tòa nhà/tầng, đọc cấu trúc/phòng và quản lý bản đồ. Phần còn thiếu là sửa/xóa tòa nhà/tầng và tạo/sửa/xóa phòng.

### 1.10. Nội dung, media và API chi tiết bổ sung

- `POST /artifacts/{artifactId}/contents/manual`: chưa có luồng nhập thủ công riêng. POST contents chung đã được dùng và có thể nhận `isAiGenerated=false`; không bắt buộc phải dùng cả hai route để đạt cùng mục tiêu.
- `GET /artifacts/{artifactId}/contents/published/all`: chưa gọi; đọc bản xuất bản theo một ngôn ngữ đã được dùng.
- `PATCH /artifacts/{artifactId}/model-3d/settings`: chưa có UI lưu cấu hình viewer qua API này.
- `GET /artifacts/{artifactId}/viewer`, `GET /artifacts/{artifactId}/viewer-ui`: chưa được FE riêng sử dụng; FE đang dùng viewer riêng và các endpoint media/model. Đây là phương án hiển thị bổ sung, không tự động là chức năng bắt buộc còn thiếu.
- `GET /tours/{id}`: FE dùng danh sách tour/manage chứa các điểm dừng, chưa gọi route chi tiết riêng.
- `GET /museums/{id}`: có wrapper trong service, chưa thấy màn gọi wrapper này. Giao diện chi tiết hiện dùng bản ghi từ danh sách.
- `PUT /feedbacks/{id}`, `GET /feedbacks/visit/{visitId}`: chưa có luồng sửa/tải lại đánh giá theo lượt; gửi đánh giá, staff phản hồi và moderation đã nối.
- `GET /complaints/me/{id}`, `GET /complaints/{id}`: FE hiện đọc danh sách, chưa gọi route lấy chi tiết riêng; tạo, nhận xử lý và đổi trạng thái đã nối.

Các route thay thế/chi tiết trong mục này không nhất thiết đều phải bổ sung UI riêng nếu dữ liệu hiện có đã đáp ứng màn hình.

## 2. Phần chưa thấy API BE hoàn chỉnh

| Nghiệp vụ | Tình trạng mã nguồn hiện tại |
| --- | --- |
| Hoàn tiền | Chưa thấy API yêu cầu/duyệt/từ chối/thực hiện hoàn, chính sách tỷ lệ và điều chỉnh quyền sau hoàn. Complaint chưa phải refund. DBML có bảng refunds nhưng code nghiệp vụ chưa tương ứng. |
| Nhật ký quản trị | Chưa thấy API ghi/tra cứu audit log phục vụ UI; DBML có audit_logs. |
| Sự cố vận hành và chất lượng AI | Chưa thấy API lưu/tra cứu/phân công/xử lý ai_quality_logs hoặc ticket sự cố. Các endpoint health AI đã có chỉ kiểm tra tình trạng dịch vụ. |
| Chatbot có lưu hội thoại/RAG | Chưa thấy API .NET hoặc service AI hiện tại quản lý source_documents, conversations, messages, message_sources và hỏi đáp theo nguồn được duyệt. TTS, nhận diện ảnh và 3D Scan đã có service riêng. |
| Tour AI cá nhân hóa có lưu | TourService hiện là CRUD/xuất bản tour có thứ tự; chưa thấy API đề xuất bằng AI theo sở thích/thời gian, lưu tour cá nhân và sửa lộ trình cá nhân. |
| Kết nối cổng thanh toán thật | Đã có payment attempt và nhân viên xác nhận; chưa thấy tích hợp provider, webhook/callback có xác thực chữ ký và xử lý kết quả từ cổng thanh toán. |
| Khôi phục mật khẩu và quản lý phiên nâng cao | AuthController mới có login/register. Chưa có forgot/reset password cho Visitor, refresh token hoặc server-side logout/revoke session. Admin có thể đổi mật khẩu qua PUT tài khoản; không đồng nghĩa đã có luồng quên mật khẩu. |
| Cài đặt qua trang quản trị | Một số quy tắc nằm trong cấu hình BE, nhưng chưa thấy API Admin đọc/cập nhật cấu hình hệ thống hoặc chính sách hoàn tiền. |
| Danh sách bản đồ dành cho Visitor theo bảo tàng | GET indoor-maps theo museum hiện yêu cầu Admin/Museum Staff. API public tải một sơ đồ đã xuất bản theo mapId đã có, nhưng chưa có route công khai liệt kê sơ đồ đã xuất bản theo museumId. |
| Bật/tắt Google Maps độc lập | FE hiện dựa vào isActive bảo tàng. Chưa thấy trường/API độc lập cho phép giữ bảo tàng hoạt động nhưng riêng phần bản đồ bị ẩn. |
| Đồng bộ bookmark/hồ sơ Visitor | Chưa thấy API bookmark hoặc Visitor tự cập nhật hồ sơ; bookmark/cỡ chữ/chuyển động hiện lưu cục bộ. Chỉ cần phát triển nếu phạm vi yêu cầu đồng bộ tài khoản/nhiều thiết bị. |
| Triển lãm chuyên đề | Chưa thấy API nghiệp vụ triển lãm trong bộ controller hiện tại. Xác nhận phạm vi trước khi phát triển thêm. |

## 3. Có code nhưng còn thiếu tích hợp/quyền

- Commerce giới hạn nhóm quản lý ở Admin/Museum Staff. System Staff chưa có quyền đối soát trong nhóm route này; không nên ghi là BE chưa có giao dịch.
- QR đọc nội dung đã có; nối thêm POST recognitions/qr để hoàn thiện chuỗi **quét → tiến độ → mở quiz → điểm → huy hiệu**.
- Quiz của Visitor đã dùng BE, nhưng thiếu UI lưu/kiểm duyệt/xuất bản ngân hàng câu hỏi ở web. Có thể không có quiz để cấp nếu chưa chuẩn bị dữ liệu ở BE.
- Xác nhận thanh toán đã có xử lý cấp pass/hóa đơn cho đơn phù hợp; FE chưa nối UI và chưa có tích hợp payment gateway thật.
- API doanh thu đã có. Không xếp doanh thu toàn bộ vào nhóm BE chưa code.

## 4. Ưu tiên nối tiếp

1. Phân công nhân viên/Curator và ngân hàng câu hỏi → có dữ liệu đúng phạm vi để vận hành.
2. Ghi nhận QR + visitId + RequestId → tiến độ, daily quiz và tích điểm hoạt động thống nhất.
3. Cấu hình sản phẩm + xác nhận thanh toán cho đúng role + mã nhóm/quyền premium.
4. Lịch sử quiz/sổ điểm, báo cáo revenue và dẫn đường Visitor theo visit/map.
5. Bổ sung BE cho refund, audit/sự cố và chatbot/tour AI theo phạm vi nhóm chốt.

## 5. Nguồn chính

- BE: `SMGS.API/Controllers/VisitorExperienceControllers.cs`, `CommerceController.cs`, `AccountsController.cs`, `TopicsController.cs`, `IndoorMapsController.cs`, `ArtifactAssetsController.cs`, `ArtifactContentSubmissionsController.cs`, `FeedbacksController.cs`, `ComplaintsController.cs`, `AuthController.cs`.
- BE service: `SMGS.Infrastructure/Services/RecognitionService.cs`, `CommerceService.cs`, `TourService.cs`, `QuestionBankService.cs`, `VisitorNavigationService.cs`, `DependencyInjection.cs` (file cuối nằm ở SMGS.Infrastructure).
- FE: `smgs_web/src/context/AppContext.jsx`, `components/indoor_maps/IndoorMapManager.jsx`, `components/artifacts/ArtifactMediaPanel.jsx`, các service và `smgs_mobile/lib/screens/artifact/daily_quiz_screen.dart`, `artifact_qr_scanner.dart`, `screens/profile`, `services/indoor_map_api_service.dart`.
- DB thiết kế: `BackEnd/project-docs/smgs_schema.dbml`. Đây là nguồn đặc tả, không chứng minh các bảng/chức năng đã được triển khai trong DB đang chạy.
- AI: route trong `AI-System/TTS AI/app/main.py`, `AI Vision/app/main.py`, `3D Scan/app/main.py`.

Tài liệu `API_Roles_And_Interfaces.md` ngày 22/10/2026 còn mô tả bộ API cũ; không dùng các số lượng/trạng thái cũ làm kết quả audit hiện tại.
