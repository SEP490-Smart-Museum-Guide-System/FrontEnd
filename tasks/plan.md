# Implementation Plan: Comprehensive BE API vs FE UI Audit & Gap Analysis

## Overview
Tiến hành tổng duyệt toàn diện 100% toàn bộ API Backend hiện có (từ ASP.NET Core `SMGS.API` Controller & Swagger) và đối chiếu chi tiết với mã nguồn giao diện thực tế của Frontend (Web React `smgs_web` và Mobile Flutter `smgs_mobile`) cho tất cả các vai trò người dùng (Admin, Curator, Museum Staff, Supporter, Visitor). Tiêu chí đánh giá tuân thủ nghiêm ngặt: một API chỉ được coi là "Có" khi **đã có màn hình giao diện UI thực tế, có hành động người dùng kích hoạt, và truyền nhận dữ liệu thật hoạt động 100%**, phân biệt rạch ròi với việc chỉ khai báo hàm service wrapper hoặc UI dùng dữ liệu mock/tĩnh.

## Architecture & Audit Decisions
1. **Nguồn chân lý Backend (Source of Truth)**:
   - Quét trực tiếp toàn bộ 27 Controller trong `D:\CAPSTONE\BackEnd\Smart_Museum_Guide_System\SMGS.API\Controllers`, bóc tách đầy đủ Route template, HTTP Method, Parameters, và Phân quyền `[Authorize(Roles = ...)]` tương ứng chuẩn Swagger specification.
2. **Quy chuẩn đánh giá trạng thái FE (Strict 3-Tier Status)**:
   - 🟢 **HOẠT ĐỘNG 100% (Fully Connected & UI Active)**: Đã có Component/Screen UI cụ thể trong Web/Mobile, có trigger (useEffect/initState/button click/form submit), render dữ liệu response thật hoặc gửi payload thật lên BE thành công.
   - 🟡 **DỞ DANG / CÓ SERVICE / DÙNG MOCK (Partial / Mock / Service Only)**: Đã viết method trong `services/`, nhưng màn hình UI chưa gọi, hoặc UI đang import file JSON/mock tĩnh (`mock_artifacts.dart`, `src/data/*.json`), hoặc UI bị disable/ẩn.
   - 🔴 **THIẾU HOÀN TOÀN (Missing on FE)**: BE đã có API và đã test thành công trên Swagger, nhưng FE chưa có bất kỳ màn hình, form nhập liệu hay nút bấm nào để người dùng tương tác.
3. **Phân bổ theo vai trò (Role-based Mapping)**:
   - **Web (`smgs_web`)**: Admin, MuseumStaff, Curator, Supporter.
   - **Mobile (`smgs_mobile`)**: Visitor (Khách tham quan), Anonymous.

## Task List

### Phase 1: Master Backend API Catalog Extraction
- [ ] Task 1: Bóc tách và lập danh mục chuẩn hóa 100% API Backend từ `SMGS.API/Controllers` kèm phân quyền và HTTP Method.

### Checkpoint 1: Backend Catalog Verified
- [ ] Danh mục API BE đầy đủ không sót controller nào, sẵn sàng làm ma trận đối chiếu.

### Phase 2: Web Frontend (`smgs_web`) Audit
- [ ] Task 2: Rà soát thực tế từng màn hình Web React đối chiếu với API Admin, Curator, Staff, Supporter.

### Checkpoint 2: Web Audit Verified
- [ ] Tất cả các component trong `smgs_web/src/components` đã được kiểm tra luồng gọi API và dữ liệu thực tế.

### Phase 3: Mobile Frontend (`smgs_mobile`) Audit
- [ ] Task 3: Rà soát thực tế từng màn hình Mobile Flutter đối chiếu với API Visitor và Khách tham quan.

### Checkpoint 3: Mobile Audit Verified
- [ ] Tất cả các screen trong `smgs_mobile/lib/screens` và widget tương ứng đã được kiểm tra mức độ phụ thuộc mock data vs API thật.

### Phase 4: Synthesis & Comprehensive Audit Matrix
- [ ] Task 4: Tổng hợp Báo cáo Kiểm toán Đối chiếu API BE vs FE Toàn diện (Audit Matrix Report) lưu tại `docs/API_FE_COMPREHENSIVE_AUDIT_2026_11_21.md`.

### Phase 5: Action & Remediation Roadmap
- [ ] Task 5: Xây dựng lộ trình bổ sung và khắc phục các lỗ hổng giao diện FE theo mức độ ưu tiên nghiệp vụ.

### Checkpoint 4: Complete
- [x] Báo cáo kiểm toán hoàn tất, đầy đủ minh chứng component/screen và phân loại 3 màu rõ ràng.
- [x] Sẵn sàng trình bày cho người dùng phê duyệt lộ trình triển khai tiếp theo.

### Phase 6: Implementation - Remediation Phase 1 (P0: Core Mobile Flows)
- [x] Task 6.1: Nối API Hoàn tất chuyến đi (`POST /api/visits/{id}/complete`) và Đánh giá phản hồi (`POST /api/feedbacks`) với dialog `VisitCompleteFeedbackDialog`.
- [x] Task 6.2: Hiển thị đánh giá công khai từ cộng đồng (`GET /api/feedbacks/museum/{id}`) trên `MuseumDetailScreen`.
- [x] Task 6.3: Xóa bỏ khung mô phỏng AI giả trong `QRScanScreen`, nối trực tiếp `VisionApiService.recognizeArtifact` và Backend API hiện vật thật.

### Phase 7: Implementation - Remediation Phase 2 (P1: Web Curation & Operations Completion)
- [x] Task 7.1: Kết nối quy trình Giám tuyển Lộ trình Tour: duyệt (`POST /api/tours/versions/{id}/approve`) và từ chối (`POST /api/tours/versions/{id}/reject`) trong `CurationCenter.jsx`.
- [x] Task 7.2: Bổ sung nút gửi duyệt tour (`POST /api/tours/versions/{id}/submit`) và badge trạng thái trong `TourManager.jsx`.
- [x] Task 7.3: Xác thực hoạt động 100% của `UserManager.jsx` (cập nhật thông tin `PUT admin/accounts/{id}`, đổi vai trò `PUT admin/accounts/{id}/roles`, quản lý phân công bảo tàng).
- [x] Task 7.4: Chuyển đổi `AuditLogs.jsx` từ giao diện giả lập thành Trung tâm Giám sát Hạ tầng Cụm Microservice AI (`AiClusterHealthPanel`) và Nhật ký Vận hành thời gian thực.

### Phase 8: Implementation - Remediation Phase 3 (P2: Experience & Utilities Completion)
- [x] Task 8.1: Bổ sung nút "Lưu lộ trình" và tab "Lộ trình đã lưu" trên Mobile (`POST & GET /api/tours/saved-routes`).
- [x] Task 8.2: Đồng bộ Quiz hiện vật ủy quyền trực tiếp cho `DailyQuizScreen` kết nối `POST /api/quiz-attempts`.
- [x] Task 8.3: Xác nhận đồng bộ trạng thái Hoãn Quiz (`PUT /api/daily-quizzes/{id}/deferred`).
- [x] Task 8.4: Bổ sung chức năng gỡ ảnh bìa bảo tàng (`DELETE /api/museums/{id}/image`) trong `MuseumCoverPicker.jsx` & `MuseumManager.jsx`.

### Phase 9: Final 100% Full System Coverage (Remaining 9 Secondary Endpoints)
- [x] Task 9.1: Cấu hình hiển thị 3D & Camera (`PATCH /api/artifacts/{id}/model-3d/settings`) trong `Artifact3DPanel.jsx`.
- [x] Task 9.2: Liên kết mô hình Sketchfab (`PUT /api/artifacts/{id}/model-3d/sketchfab`) trong `Artifact3DPanel.jsx`.
- [x] Task 9.3: Nút mở 3D Viewer UI toàn màn hình (`GET /api/artifacts/{id}/viewer-ui`) trong `Artifact3DPanel.jsx`.
- [x] Task 9.4: Tự động nạp chi tiết chủ đề (`GET /api/topics/{id}`) khi mở modal trong `TopicManager.jsx`.
- [x] Task 9.5: Nút "Tạo bản nháp mới (Clone)" cho phiên bản tour (`POST /api/tours/{tourId}/versions`) trong `TourManager.jsx` & `AppContext.jsx`.
- [x] Task 9.6: Cập nhật bản nháp phiên bản tour (`PUT /api/tours/versions/{versionId}`) trong `TourManager.jsx`.
- [x] Task 9.7: Nạp chi tiết lượt tham quan (`GET /api/visits/{id}`) qua `VisitorExperienceApi.getVisit` trong `visit_progress_screen.dart`.
- [x] Task 9.8: Nút làm lại bài thi trắc nghiệm (`POST /api/quiz-attempts/{id}/reset`) trong `daily_quiz_screen.dart` & `VisitorExperienceApi.resetQuizAttempt`.
- [x] Task 9.9: Nút "Sửa" và dialog cập nhật đánh giá của khách (`PUT /api/feedbacks/{id}`) trong `museum_detail_screen.dart` & `VisitorExperienceApi.updateFeedback`.

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Bỏ sót các endpoint được định nghĩa chung trong Controller trừu tượng (`VisitorExperienceControllers.cs`) | High | Quét đệ quy toàn bộ class kế thừa `ExperienceControllerBase` và route attribute. |
| FE có hàm gọi API nhưng trong UI bị comment out hoặc không bao giờ được trigger | High | Đọc trực tiếp code JSX/Dart của từng màn hình, tìm chính xác nơi invoke service và render state. |
| Nhầm lẫn giữa mock data và data thật trong Flutter (`mock_artifacts.dart`) | Medium | Kiểm tra cờ config (`useMockData`, `kDebugMode`) hoặc các hardcode list trong `lib/screens`. |

## Open Questions
- Các API về thanh toán SePay webhook (`/api/payments/sepay/webhook`) bản chất là server-to-server, FE chỉ xử lý trang hiển thị trạng thái đơn hàng/QR chuyển khoản.
