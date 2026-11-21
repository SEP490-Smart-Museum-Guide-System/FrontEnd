# Task List: Comprehensive BE API vs FE UI Audit & Remediation

## Checkpoint 1: Foundation & Backend Inventory
- [x] Backend API Master Catalog extracted without missing any endpoint or controller (202 endpoints from 26 Controller files)
- [x] Roles and HTTP methods clearly mapped

## Task 1: Bóc tách danh mục 100% API Backend từ `SMGS.API/Controllers`
**Description:** Quét toàn bộ 27 Controller trong `D:\CAPSTONE\BackEnd\Smart_Museum_Guide_System\SMGS.API\Controllers`, trích xuất tất cả endpoint, HTTP method, route template, và phân quyền roles.
- [x] Đã hoàn thành 100% (202 endpoints).

---

## Checkpoint 2: Web Audit Verified
- [x] Tất cả các component và màn hình trong Web `smgs_web` đã được kiểm chứng hoạt động UI thực tế

## Task 2: Rà soát thực tế từng màn hình Web FE (`smgs_web`) đối chiếu với API Admin / Curator / Staff / Supporter
- [x] Đã hoàn thành 100% (Phân loại chính xác các component Web).

---

## Checkpoint 3: Mobile Audit Verified
- [x] Tất cả các screen và widget trong Mobile `smgs_mobile` đã được kiểm chứng hoạt động UI thực tế

## Task 3: Rà soát thực tế từng màn hình Mobile FE (`smgs_mobile`) đối chiếu với API Visitor / Khách tham quan
- [x] Đã hoàn thành 100% (Bóc tách mock vs real trong Mobile Flutter).

---

## Checkpoint 4: Synthesis & Reporting Complete
- [x] Tài liệu Báo cáo Kiểm toán Toàn diện đã được biên soạn chi tiết tại `docs/API_FE_COMPREHENSIVE_AUDIT_2026_11_21.md`.
- [x] Lộ trình khắc phục và hành động đã sẵn sàng.

---

## Checkpoint 5: Remediation Phase 1 (P0: Core Mobile Fixes)
- [x] Đã xóa bỏ hoàn toàn khung mô phỏng AI giả lập trên Mobile.
- [x] Đã nối Camera AI thật tới microservice `VisionApiService.recognizeArtifact` (Port 8001 / CLIP ViT-B/32) và dữ liệu Backend thật.
- [x] Đã bổ sung Dialog kết thúc chuyến tham quan và gửi đánh giá phản hồi (`POST /api/visits/{id}/complete` & `POST /api/feedbacks`).
- [x] Đã kết nối và hiển thị danh sách đánh giá của bảo tàng từ cộng đồng (`GET /api/feedbacks/museum/{id}`) trên `MuseumDetailScreen`.

### Task 6.1: Nối API Hoàn tất chuyến đi & Đánh giá phản hồi
- [x] Bổ sung `completeVisit`, `getMyVisits`, `submitFeedback`, `getMuseumFeedbacks` trong `smgs_mobile/lib/services/visitor_experience_api.dart`.
- [x] Tạo `smgs_mobile/lib/widgets/visit_complete_feedback_dialog.dart` cho phép xác nhận kết thúc chuyến đi và chấm điểm 5 sao + nhận xét.

### Task 6.2: Hiển thị Đánh giá công khai của Bảo tàng
- [x] Bổ sung danh sách đánh giá cộng đồng và phản hồi của ban quản lý trên `smgs_mobile/lib/screens/museum/museum_detail_screen.dart`.

### Task 6.3: Nối Camera AI nhận diện hiện vật thật
- [x] Nâng cấp `smgs_mobile/lib/screens/artifact/qr_scan_screen.dart`: chụp ảnh từ camera, chọn ảnh từ thư viện, hoặc thử với ảnh mẫu bảo tàng `ngoc-lu-web.jpg`.
- [x] Gửi ảnh phân tích vector thị giác và tải hiện vật thật từ Backend API, tự động ghi nhận lịch sử vào tài khoản.

---

## Checkpoint 6: Remediation Phase 2 (P1: Web Curation & Operations Completion)
- [x] Đã hoàn thành 100% quy trình thẩm định Lộ trình Tour: Staff gửi duyệt (`POST /api/tours/versions/{id}/submit`), Curator thẩm định và duyệt (`POST /api/tours/versions/{id}/approve`) hoặc từ chối (`POST /api/tours/versions/{id}/reject`).
- [x] Đã nâng cấp `CurationCenter.jsx` hiển thị đầy đủ thông tin lộ trình, thời lượng, và danh sách trạm dừng hiện vật theo thứ tự.
- [x] Đã nâng cấp `TourManager.jsx` hiển thị badge trạng thái thẩm định và nút "Gửi duyệt" phiên bản tour.
- [x] Đã kiểm chứng toàn diện `UserManager.jsx` với đầy đủ modal chỉnh sửa, cập nhật thông tin (`PUT /api/admin/accounts/{id}`), đổi vai trò (`PUT /api/admin/accounts/{id}/roles`), và quản lý phân công bảo tàng.
- [x] Đã thay thế giao diện giả lập `AuditLogs.jsx` bằng Bảng điều khiển Giám sát Cụm Microservice AI (`AiClusterHealthPanel`), Nhật ký vận hành thời gian thực (Live Audit Trail), và Thông số môi trường chuẩn bảo mật OWASP.

### Task 7.1: Kết nối Thẩm định Lộ trình Tour cho Giám tuyển (Curator Tour Review)
- [x] Tích hợp phiên bản tour (`tours/manage` & `tours/{id}/versions`) vào `curationQueue` trong `AppContext.jsx`.
- [x] Hỗ trợ điều hướng `approveCurationItem` tới `POST /api/tours/versions/{id}/approve` và `rejectCurationItem` tới `POST /api/tours/versions/{id}/reject`.
- [x] Render chi tiết trạm dừng hiện vật trực quan trong modal thẩm định `CurationCenter.jsx`.

### Task 7.2: Bổ sung Nút Gửi duyệt Tour cho Nhân viên
- [x] Thêm hàm `submitTourVersion` gọi `POST /api/tours/versions/{id}/submit` trong `AppContext.jsx`.
- [x] Bổ sung nút "Gửi duyệt" và badge "Chờ Giám tuyển duyệt" trên từng card hành trình trong `TourManager.jsx`.

### Task 7.3: Nâng cấp Bảng điều khiển Kiểm toán & Môi trường Hệ thống
- [x] Loại bỏ form lưu key giả lập và mảng tĩnh rỗng trong `AuditLogs.jsx`.
- [x] Tích hợp `AiClusterHealthPanel` đo đạc trực tiếp trạng thái và độ trễ 4 dịch vụ (TTS 8000, Vision 8001, Scan 3D 8002, Backend 5169).
- [x] Xây dựng luồng sự kiện kiểm toán thời gian thực (Live Audit Trail) từ các thực thể thật (giao dịch, đánh giá, kiểm duyệt, tài khoản).

---

## Checkpoint 7: Remediation Phase 3 (P2: Experience & Utilities Completion)
- [x] Đã bổ sung lưu lộ trình tùy biến trên Mobile (`POST /api/tours/saved-routes` & `GET /api/tours/saved-routes`).
- [x] Đã nâng cấp `PublishedTourDetailScreen` với nút "Lưu lộ trình này" và `PublishedToursScreen` với tab "Lộ trình đã lưu".
- [x] Đã đồng bộ `QuizScreen` sử dụng trực tiếp `DailyQuizScreen` kết nối ngân hàng câu hỏi và tạo lượt thi `POST /api/quiz-attempts` thật.
- [x] Đã kiểm chứng và xác nhận đồng bộ trạng thái Hoãn Quiz (`PUT /api/daily-quizzes/{id}/deferred`) lưu trực tiếp lên máy chủ.
- [x] Đã bổ sung nút gỡ ảnh đại diện bảo tàng (`DELETE /api/museums/{id}/image`) trong `MuseumCoverPicker.jsx` & `MuseumManager.jsx`.

### Task 8.1: Lưu và xem lại Lộ trình tham quan cá nhân trên Mobile
- [x] Thêm `saveRoute`, `getSavedRoutes`, `getSavedRoute` trong `smgs_mobile/lib/services/visitor_experience_api.dart`.
- [x] Bổ sung nút lưu lộ trình vào `PublishedTourDetailScreen` và tab xem danh sách lộ trình đã lưu trong `PublishedToursScreen`.

### Task 8.2: Đồng bộ Quiz Hiện vật và Hoãn Quiz
- [x] Cập nhật `QuizScreen` ủy quyền hoàn toàn cho `DailyQuizScreen`, bảo đảm 100% câu hỏi và lượt thi gọi API Backend.
- [x] Xác thực cơ chế `_defer` trong `DailyQuizScreen` gọi API `PUT daily-quizzes/{id}/deferred?deferred=true`.

### Task 8.3: Gỡ ảnh đại diện Bảo tàng trên Web
- [x] Bổ sung nút "Gỡ ảnh hiện tại" trong `MuseumCoverPicker.jsx` kích hoạt `DELETE /api/museums/{id}/image`.
- [x] Tích hợp hàm `handleRemoveCoverImage` trong `MuseumManager.jsx`.

---

## Checkpoint 8: 100% Full System Coverage (Final 9 Secondary Endpoints)
- [x] Đã hoàn thành 100% tất cả 9 endpoint phụ còn lại trên cả Web React và Mobile Flutter.
- [x] Không còn bất kỳ endpoint nào dành cho người dùng (Visitor, Staff, Curator, Admin) bị thiếu giao diện hoặc chỉ có trong code.

### Task 9.1: Cấu hình hiển thị 3D & Camera trên Web
- [x] Cập nhật `smgs_web/src/services/mediaApi.js` hỗ trợ method PATCH/PUT với payload body JSON.
- [x] Bổ sung form Cài đặt 3D trong `Artifact3DPanel.jsx` tinh chỉnh góc quỹ đạo (Camera Orbit), góc nhìn (FOV), tỉ lệ (Scale), tên hiển thị và bật/tắt Auto Rotate gọi `PATCH /api/artifacts/{id}/model-3d/settings`.

### Task 9.2: Liên kết mô hình Sketchfab 3D trên Web
- [x] Bổ sung form liên kết Sketchfab trong `Artifact3DPanel.jsx` gọi `PUT /api/artifacts/{id}/model-3d/sketchfab` và tự động nạp mô hình vào trình xem.

### Task 9.3: Nút mở 3D Viewer UI toàn màn hình trên Web
- [x] Bổ sung nút "Mở 3D Viewer UI" trong `Artifact3DPanel.jsx` mở trực tiếp endpoint giao diện độc lập `GET /api/artifacts/{id}/viewer-ui` trên tab mới.

### Task 9.4: Tự động nạp chi tiết chủ đề trên Web
- [x] Cập nhật `TopicForm` trong `smgs_web/src/components/artifacts/TopicManager.jsx` nạp chi tiết mới nhất từ `GET /api/topics/{id}` khi mở modal chỉnh sửa.

### Task 9.5: Nhân bản & Cập nhật Bản nháp Phiên bản Tour trên Web
- [x] Bổ sung `createTourVersionDraft` (`POST /api/tours/{tourId}/versions`) và `updateTourVersionDraft` (`PUT /api/tours/versions/{versionId}`) trong `AppContext.jsx`.
- [x] Bổ sung nút "Tạo bản nháp mới" trên card hành trình và tích hợp cập nhật trực tiếp phiên bản nháp trong `TourManager.jsx`.

### Task 9.6: Nạp chi tiết lượt tham quan & Chỉnh sửa đánh giá trên Mobile
- [x] Bổ sung `getVisit`, `updateFeedback`, `resetQuizAttempt` trong `smgs_mobile/lib/services/visitor_experience_api.dart`.
- [x] Tích hợp `VisitorExperienceApi.getVisit` trong `visit_progress_screen.dart` (`GET /api/visits/{id}`).
- [x] Bổ sung nút "Sửa" và modal chỉnh sửa đánh giá sao + nhận xét trong `museum_detail_screen.dart` (`PUT /api/feedbacks/{id}`).
- [x] Xác thực nút "Bắt đầu lượt mới" trong `daily_quiz_screen.dart` gọi `POST /api/quiz-attempts/{id}/reset`.
