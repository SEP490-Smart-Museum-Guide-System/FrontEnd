# Đối chiếu SMGS với Use Case Diagram

Tài liệu này đối chiếu bản Flutter Web với sơ đồ **Smart Museum Guide System (SMGS) – Use Case Diagram** do nhóm cung cấp. Mức độ được hiểu như sau:

- **Đầy đủ:** có giao diện, trạng thái và luồng chính/luồng thay thế trong prototype.
- **Mô phỏng:** hoàn thành được luồng trên web nhưng chưa kết nối phần cứng, máy chủ hoặc dịch vụ bên ngoài.
- **Ngoài phạm vi mobile:** thuộc hệ thống nhân viên/quản trị; đặc tả hiện tại yêu cầu thiết kế riêng trước khi triển khai.

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
| Manage Museum Content; Manage Artifact Information; Manage Media; Manage Gallery / Museum Map | Ngoài phạm vi mobile | `SMGS_Main_Flow_Full_Spec.md` nêu MF-07 cần đặc tả quản trị riêng; chưa có quyền, trạng thái bản nháp, phiên bản hay quy tắc xóa. |
| Generate AI Content; Generate Narration; Generate Quiz Content | Ngoài phạm vi mobile | Prototype khách tham quan chỉ dùng dữ liệu mẫu qua các service interface. Chưa có yêu cầu về mô hình, nguồn, kiểm duyệt hay chi phí. |
| Review / Edit AI Content; Approve / Reject Content; Publish Content | Ngoài phạm vi mobile | MF-08 chưa định nghĩa trạng thái duyệt, vai trò reviewer, lịch sử chỉnh sửa, rollback và audit. |
| View Visitor Feedback / Museum Reports | Ngoài phạm vi mobile | Ứng dụng hiện ghi góp ý trong phiên để kiểm thử Visitor flow; chưa truyền dữ liệu lên hệ thống báo cáo. |

## Administrator Use Cases

| Nhóm use case | Trạng thái | Dữ liệu cần có trước khi triển khai |
|---|---|---|
| Manage Users; Manage Roles & Permissions | Ngoài phạm vi mobile | Ma trận quyền, chính sách mời/khóa/xóa tài khoản và khôi phục. |
| Manage Museums; Assign Staff to Museum | Ngoài phạm vi mobile | Mô hình tổ chức, phạm vi nhân viên, vòng đời bảo tàng và quyền điều chuyển. |
| Monitor Transactions | Ngoài phạm vi mobile | Giao dịch thật, webhook, đối soát, hoàn tiền và trạng thái từ cổng thanh toán. |
| View Audit Logs | Ngoài phạm vi mobile | Sự kiện cần ghi, thời hạn lưu, dữ liệu nhạy cảm và quyền đọc log. |
| Manage System Settings | Ngoài phạm vi mobile | Danh sách cấu hình, phạm vi toàn hệ thống/theo bảo tàng và quy tắc phê duyệt. |

Không nên dựng các màn hình Staff/Admin giả khi những quy tắc trên chưa được chốt, vì giao diện sẽ khóa cứng sai mô hình quyền và quy trình nghiệp vụ.

## Payment Use Cases và hệ thống bên ngoài

`PaymentService` tách khỏi giao diện. Bản web dùng `MockPaymentService`, nên có thể thay bằng adapter VNPay/MoMo hoặc cổng khác sau này. Khi tích hợp thật cần bổ sung tạo giao dịch phía máy chủ, chữ ký/xác minh callback, idempotency, đối soát và chỉ kích hoạt quyền sau khi máy chủ xác nhận trạng thái thanh toán.

## Kết luận phạm vi

- **Nhóm Visitor:** trùng khớp đầy đủ ở mức Flutter Web prototype; các chức năng phụ thuộc phần cứng/dịch vụ ngoài được mô phỏng và ghi nhãn rõ.
- **Nhóm Staff / Curator, Administrator:** có trong sơ đồ toàn hệ thống nhưng không thuộc bản mobile visitor hiện tại, đúng với ranh giới trong đặc tả luồng chính.
- **Payment Gateway:** có ranh giới service và đủ luồng thành công/thất bại trong prototype; chưa kết nối giao dịch thật.

Các tệp kiểm thử chính: `test/main_flows_test.dart`, `test/widget_test.dart`, `test/home_test.dart`, `test/motion_test.dart`.
