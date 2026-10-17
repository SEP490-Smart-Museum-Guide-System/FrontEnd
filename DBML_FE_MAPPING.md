# Đối chiếu FE với `smgs_schema.dbml`

Tài liệu này ghi nhận cách frontend SMGS dùng schema tại [`../BackEnd/project-docs/smgs_schema.dbml`](../BackEnd/project-docs/smgs_schema.dbml). Schema hiện được ghi chú là **đề xuất chưa chốt**, nên FE chỉ dùng nó làm hợp đồng dữ liệu để chuẩn bị kết nối API; FE chưa truy cập trực tiếp PostgreSQL.

## Quy ước chung

- Database: PostgreSQL.
- Định danh backend: `uuid` cho Identity, `int`/`bigint` cho nghiệp vụ. Mock FE đang dùng chuỗi dễ đọc (`mus-01`, `art-001`, `TXN-98421`) và sẽ thay bằng ID API khi có backend.
- Thời gian API nên trả ISO 8601 có timezone (`timestamptz`).
- Role hợp lệ: `Admin`, `SystemStaff`, `MuseumStaff`, `Curator`, `Visitor`. Mỗi tài khoản một role qua `UserRoles`.
- Content status hợp lệ theo enum `content_status`: `draft`, `pending_review`, `published`, `rejected`, `archived`.

## Quyền và dữ liệu theo role

| Role DB | Màn FE | Bảng/phạm vi dữ liệu |
| --- | --- | --- |
| `Admin` | Tổng quan, nhân sự, bảo tàng, giao dịch, nhật ký | `Users`, `Roles`, `UserRoles`, `museums`, `orders`, `payment_transactions`, `audit_logs` (API sau này). |
| `SystemStaff` | Hỗ trợ, hoàn tiền, đối soát, kiểm duyệt feedback, vận hành AI | `complaints`, `refunds`, `payment_transactions`, `feedbacks`, `source_documents`. |
| `MuseumStaff` | Hiện vật, media/QR/bản đồ, tour, xưởng AI, đệ trình | Bị giới hạn bởi `staff_assignments.museum_id`; dùng `artifacts`, `media`, `tours`, các bảng phiên bản nội dung. |
| `Curator` | Hàng đợi thẩm định, tra cứu hiện vật, nhật ký thẩm định | Cùng phạm vi `staff_assignments.museum_id`; chỉ role này duyệt nội dung. |
| `Visitor` | Flutter mobile | `museums`, nội dung `published`, `visits`, `recognition_history`, quiz, quyền truy cập và feedback. |

## Mapping màn hình và bảng

| Tính năng FE | Bảng DB chính | Lưu ý tích hợp |
| --- | --- | --- |
| Đăng nhập và phân quyền | `Users`, `Roles`, `UserRoles`, `user_profiles`, `staff_assignments` | API đăng nhập trả profile, role duy nhất và danh sách/phạm vi `museum_id`. Không trả `PasswordHash`. |
| Bảo tàng, địa chỉ, chỉ đường | `museums`, `buildings`, `floors`, `galleries` | Dùng `latitude`, `longitude`, `address`, `is_active`. Cờ `googleMapsVisible` hiện là cờ UI demo, cần bổ sung vào API/schema nếu Admin phải điều khiển công khai bản đồ. |
| Hiện vật, QR, vị trí trong nhà | `artifacts`, `artifact_reference_images`, `media`, `map_nodes`, `map_edges` | `qr_code` khác `access_rights.ticket_code`; FE không được dùng lẫn hai mã này. |
| Nội dung hiện vật đa ngôn ngữ | `artifact_contents`, `artifact_content_versions`, `languages` | Museum Staff tạo version; Curator ghi `reviewed_by`, `reviewed_at`, `review_note`, `published_at`. |
| Thuyết minh AI | `narrations`, `narration_versions`, `media` | `is_ai_generated` lưu ở version, audio ở `audio_url` hoặc media. |
| Quiz AI | `questions`, `question_options`, `quizzes`, `quiz_questions` | Curator duyệt `questions`/`quizzes`; Visitor chỉ nhận item `published`. |
| Nguồn tri thức và AI Guide | `source_documents`, `conversations`, `messages`, `message_sources` | Mỗi câu trả lời AI nên có nguồn dẫn chiếu từ `message_sources`. |
| Tour và lịch sử tham quan | `tours`, `tour_items`, `visits`, `visit_items`, `recognition_history` | Tour template và tour AI phân biệt bằng `tour_type`; tour AI cá nhân dùng `owner_user_id`. |
| Điểm, huy hiệu và kết quả quiz | `point_transactions`, `badges`, `user_badges`, `daily_quiz_entries`, `quiz_attempts`, `quiz_attempt_answers` | Không cập nhật trực tiếp `total_points` từ app; backend ghi ledger rồi cập nhật profile. |
| Mua dịch vụ và hoàn tiền | `products`, `orders`, `order_items`, `payment_transactions`, `access_rights`, `refunds`, `invoices` | FE dùng trạng thái đơn hàng/thanh toán/hoàn tiền riêng, không gộp thành một `transaction.status`. |
| Feedback và khiếu nại | `feedbacks`, `feedback_responses`, `complaints` | Feedback chỉ được tạo sau `visits` hoàn thành; System Staff đổi `feedbacks.status` visible/hidden. |

## Luồng kiểm duyệt FE đã đồng bộ

`Museum Staff tạo bản nháp` → `POST phiên bản với status=draft` → `đệ trình status=pending_review` → `Curator review` → `published` hoặc `rejected` hoặc trả về `draft` kèm `review_note`.

Hàng đợi mô phỏng trong [`smgs_web/src/data/mockData.js`](./smgs_web/src/data/mockData.js) hiện dùng đúng năm trạng thái `content_status`. Màn Curator thao tác thông qua [`smgs_web/src/context/AppContext.jsx`](./smgs_web/src/context/AppContext.jsx); khi nối API, ba thao tác này cần ghi vào đúng bảng phiên bản theo loại nội dung thay vì một bảng hàng đợi chung:

- `artifact_update` → `artifact_content_versions`
- `audio_narration` → `narration_versions`
- `quiz` → `questions`/`quizzes`

## Việc backend cần chốt trước khi FE nối API

1. Cột hoặc endpoint quản lý công khai Google Maps vì DBML hiện có `is_active`, chưa có `googleMapsVisible`.
2. API tổng hợp “hàng đợi Curator” từ ba nhóm bảng phiên bản nội dung.
3. Hợp đồng trạng thái thanh toán: `orders.status`, `payment_transactions.status` và `refunds.status` là ba enum khác nhau.
4. Chính sách `access_rights` để Flutter biết chính xác nội dung free/premium mà Visitor đang được dùng.
