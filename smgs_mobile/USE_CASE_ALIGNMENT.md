# Đối chiếu SMGS với Use Case Diagram

Tài liệu này đối chiếu bản Flutter Web với sơ đồ **Smart Museum Guide System (SMGS) – Use Case Diagram** do nhóm cung cấp. Mức độ được hiểu như sau:

- **Đầy đủ:** có giao diện, trạng thái và luồng chính/luồng thay thế trong prototype.
- **Mô phỏng:** hoàn thành được luồng trên web nhưng chưa kết nối phần cứng, máy chủ hoặc dịch vụ bên ngoài.
- **Giao diện mô phỏng:** có điểm vào và màn hình tổng quan để duyệt UI; thao tác dữ liệu cần đặc tả nghiệp vụ và API thật.

## Visitor Use Cases

| Use case trong sơ đồ | Mức độ | Hiện thực trong ứng dụng |
|---|---|---|
| Select Museum | Đầy đủ | Trang Khám phá, danh sách bảo tàng và chi tiết bảo tàng. |
| Discover Artifact | Đầy đủ | Từ bảo tàng hoặc tab Quét mã, người dùng chọn quét mã, nhận diện ảnh hoặc tra cứu danh sách. |
| Scan QR Code | Mô phỏng | Khung quét, đèn mô phỏng, trạng thái xử lý, ánh xạ mã mẫu và hủy/quay lại. Không xin quyền máy ảnh trên web. |
| Recognize Artifact by Image | Mô phỏng | Có trạng thái phân tích, kết quả phù hợp, không tìm thấy, thử lại và mở hiện vật. |
| Search / Browse Artifacts | Đầy đủ | Tìm kiếm có dấu/không dấu; lọc theo bảo tàng, chủ đề, chuyên đề và phòng; xóa bộ lọc và trạng thái rỗng. |
| View Artifact Information | Đầy đủ | Ảnh/minh họa, tên, thời kỳ, bảo tàng, phòng, chuyên đề, tóm tắt và câu chuyện chi tiết. |
| Interact with AI Guide | Mô phỏng | Câu hỏi gợi ý, nhập câu hỏi nối tiếp, lịch sử trò chuyện, trạng thái chờ và phản hồi ngoài phạm vi. |
| Request Audio Narration | Mô phỏng | Màn thuyết minh có đọc nội dung, phát/tạm dừng, tiến độ; chưa phát tệp âm thanh thật. Có thể đọc câu trả lời của hướng dẫn viên. |
| Ask Follow-up Questions | Mô phỏng | Cho phép gửi nhiều câu hỏi trong cùng phiên trò chuyện; câu hỏi không có nguồn được trả lời minh bạch. |
| Take Quiz | Đầy đủ | Một câu mỗi màn, bắt buộc chọn đáp án, khóa sau khi trả lời và chuyển câu tiếp theo. |
| Receive Quiz Feedback | Đầy đủ | Hiện đúng/sai, đáp án và giải thích trước khi sang câu mới. |
| Earn Points / Badges | Đầy đủ trong phiên | Tính điểm, huy hiệu khi hoàn thành tốt; chỉ giữ kết quả tốt nhất để tránh cộng trùng. |
| Get Personalized Tour | Đầy đủ trong prototype | Chọn thời lượng, nhiều sở thích và tạo lộ trình theo đúng bảo tàng. |
| Provide Interests & Available Time | Đầy đủ | 30/60/90/120 phút; Lịch sử, Nghệ thuật, Văn hóa, Khoa học; bắt buộc ít nhất một sở thích. |
| View Tour Route | Đầy đủ trong prototype | Danh sách điểm dừng và sơ đồ tầng minh họa. |
| Navigate Inside Museum | Mô phỏng | Điểm hiện tại, điểm tiếp theo, phòng trưng bày, bỏ qua điểm và kết thúc sớm; không có định vị trong nhà thật. |
| View Visit History | Đầy đủ trong phiên | Nhóm theo ngày/bảo tàng; chi tiết hiện vật, hành trình, điểm bỏ qua và lượt thử tài. |
| View Quiz Results / Progress | Đầy đủ trong phiên | Tổng điểm, số hiện vật, huy hiệu, số lượt làm và kết quả tốt nhất theo hiện vật. |
| Submit Rating / Feedback | Đầy đủ trong phiên | Nhãn đánh giá bằng chữ, bắt buộc chọn mức, bình luận tùy chọn; liên kết đúng ứng dụng/bảo tàng/hiện vật/chuyến đi. |
| Purchase Premium Content / Pass | Mô phỏng | 4 dịch vụ số theo bảo tàng và ngày; dùng thuật ngữ dịch vụ số, không gọi là vé vào cửa. |
| Process Payment | Mô phỏng | Chọn VNPay/MoMo, chọn kết quả thành công/thất bại, trạng thái xử lý và thử lại; không thu tiền thật. |
| Activate Premium Access | Đầy đủ trong phiên | Chỉ giao dịch mô phỏng thành công mới kích hoạt; chống đăng ký trùng; quyền dùng gắn với bảo tàng và ngày. |

## Quan hệ include / extend trong sơ đồ

- **Discover Artifact** dẫn đến **View Artifact Information** và được mở rộng bởi quét mã, nhận diện ảnh hoặc tra cứu danh sách.
- **Interact with AI Guide** bao gồm yêu cầu thuyết minh và cho phép câu hỏi nối tiếp.
- **Take Quiz** tạo phản hồi sau từng câu, điểm và huy hiệu khi hoàn tất.
- **Get Personalized Tour** bắt buộc thời gian/sở thích, sau đó hiển thị lộ trình; điều hướng trong bảo tàng là phần mở rộng bằng sơ đồ mẫu.
- **Purchase Premium Content / Pass** đi qua xử lý thanh toán rồi mới kích hoạt quyền sử dụng.

Các quan hệ trên đều có đường đi tương ứng trong giao diện và có kiểm thử cho nhánh chính cùng các nhánh lỗi quan trọng.

## Staff / Curator Use Cases

| Nhóm use case | Trạng thái | Lý do / ranh giới |
|---|---|---|
| Manage Museum Content; Manage Artifact Information; Manage Media; Manage Gallery / Museum Map | Giao diện mô phỏng | Không gian nghiệp vụ có điểm vào cho nhóm quản lý nội dung; CRUD thật cần API và quy tắc phiên bản. |
| Generate AI Content; Generate Narration; Generate Quiz Content | Giao diện mô phỏng | Có điểm vào tạo nội dung AI; mô hình, nguồn và chi phí chưa được kết nối. |
| Review / Edit AI Content; Approve / Reject Content; Publish Content | Giao diện mô phỏng | Có hàng đợi duyệt và xuất bản; trạng thái duyệt, rollback và audit cần backend. |
| View Visitor Feedback / Museum Reports | Giao diện mô phỏng | Có điểm vào phản hồi/báo cáo và số liệu tổng quan mẫu. |

## Administrator Use Cases

| Nhóm use case | Trạng thái | Dữ liệu cần có trước khi triển khai |
|---|---|---|
| Manage Users; Manage Roles & Permissions | Giao diện mô phỏng | Có điểm vào quản lý tài khoản và phân quyền; ma trận quyền thật cần backend. |
| Manage Museums; Assign Staff to Museum | Giao diện mô phỏng | Có điểm vào hồ sơ bảo tàng và phân công nhân sự. |
| Monitor Transactions | Giao diện mô phỏng | Có điểm vào theo dõi giao dịch; webhook, đối soát và hoàn tiền chưa kết nối. |
| View Audit Logs | Giao diện mô phỏng | Có điểm vào nhật ký; chính sách lưu và sự kiện audit cần chốt. |
| Manage System Settings | Giao diện mô phỏng | Có điểm vào cấu hình vận hành chung. |

Đăng nhập dùng chung Email/Mật khẩu và tự điều hướng theo vai trò. Khách tham quan vào giao diện mobile; Nhân viên / Kiểm duyệt viên và Quản trị viên vào dashboard web desktop có thanh điều hướng và vùng dữ liệu rộng. Tài khoản nội bộ chỉ dùng để duyệt giao diện; không cho tự đăng ký hoặc tự chọn quyền.

## Payment Use Cases và hệ thống bên ngoài

`PaymentService` tách khỏi giao diện. Bản web dùng `MockPaymentService`, nên có thể thay bằng adapter VNPay/MoMo hoặc cổng khác sau này. Khi tích hợp thật cần bổ sung tạo giao dịch phía máy chủ, chữ ký/xác minh callback, idempotency, đối soát và chỉ kích hoạt quyền sau khi máy chủ xác nhận trạng thái thanh toán.

## Kết luận phạm vi

- **Nhóm Visitor:** trùng khớp đầy đủ ở mức Flutter Web prototype; các chức năng phụ thuộc phần cứng/dịch vụ ngoài được mô phỏng và ghi nhãn rõ.
- **Nhóm Staff / Curator, Administrator:** đã có xác thực theo vai trò và giao diện tổng quan tương ứng; nghiệp vụ ghi dữ liệu vẫn ở mức mô phỏng cho đến khi có API và quy tắc chi tiết.
- **Payment Gateway:** có ranh giới service và đủ luồng thành công/thất bại trong prototype; chưa kết nối giao dịch thật.

Các tệp kiểm thử chính: `test/main_flows_test.dart`, `test/widget_test.dart`, `test/home_test.dart`, `test/motion_test.dart`.
