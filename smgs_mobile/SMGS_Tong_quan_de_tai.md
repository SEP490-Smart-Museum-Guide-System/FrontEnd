# Tổng quan đề tài Smart Museum Guide System

**Tên tiếng Việt:** Hệ thống hướng dẫn tham quan bảo tàng thông minh  
**Tên tiếng Anh:** Smart Museum Guide System  
**Tên viết tắt:** SMGS  
**Ngày cập nhật:** 18/09/2026

Tài liệu này tổng hợp phạm vi, chức năng và quy tắc nghiệp vụ của SMGS dựa trên tài liệu đề xuất `FALL26_Smart Museum Guide _TamPM.docx` và các câu trả lời làm rõ yêu cầu của chủ dự án. Hệ thống phục vụ nhiều bảo tàng, kết hợp quản lý hiện vật, hướng dẫn tham quan bằng AI, tương tác qua quiz và cung cấp dịch vụ hướng dẫn số có trả phí.

Các nội dung được người dùng xác nhận là cơ sở yêu cầu hiện tại. Những điểm chưa rõ được tập hợp ở cuối tài liệu; các giả định từng dùng để minh họa ERD không tự động trở thành yêu cầu chính thức. Tài liệu này là bản tổng quan nghiệp vụ để phát triển SRS và mô hình dữ liệu, chưa thay thế đặc tả chi tiết.

## 1. Bối cảnh và mục tiêu

Bảo tàng thường giới thiệu hiện vật qua nhãn mô tả ngắn hoặc hướng dẫn viên trực tiếp. Cách tiếp cận này có hạn chế về lượng thông tin, ngôn ngữ, khả năng trả lời câu hỏi và mức độ cá nhân hóa. SMGS sử dụng thiết bị di động để hỗ trợ khách nhận diện hiện vật, tiếp cận nội dung thuyết minh phù hợp và chủ động khám phá bảo tàng.

Hệ thống hướng đến các mục tiêu:

- Cung cấp thông tin và thuyết minh đa ngôn ngữ dựa trên nội dung đã được kiểm duyệt.
- Cho phép khách hỏi đáp với AI về nhiều hiện vật trong cùng một cuộc hội thoại.
- Đề xuất lộ trình theo sở thích và thời gian tham quan của từng lần sử dụng.
- Tăng tương tác qua các lượt quiz ngắn, điểm tích lũy và huy hiệu.
- Hỗ trợ nhân viên quản lý nội dung, phiên bản và phản hồi của khách.
- Cung cấp nguồn thu từ quyền sử dụng dịch vụ hướng dẫn số theo tour.
- Lưu dữ liệu nghiệp vụ và nhật ký để tra cứu, quản trị và phân tích hoạt động.

## 2. Phạm vi hệ thống

### 2.1. Phạm vi đã thống nhất

- Hỗ trợ **nhiều bảo tàng**, mở rộng so với phạm vi một địa điểm trong đề xuất ban đầu.
- Giữ toàn bộ nhóm chức năng của đề xuất; không loại bỏ chức năng nào ở thời điểm hiện tại.
- Khách phải đăng nhập để sử dụng ứng dụng; không có chế độ khách vãng lai.
- Cung cấp thông tin cơ bản miễn phí và dịch vụ hướng dẫn số trả phí.
- Hướng đến trải nghiệm trên thiết bị di động. Web là phương án tùy chọn theo đề xuất ban đầu; chưa có quyết định bổ sung về nền tảng triển khai.

### 2.2. Thuật ngữ nghiệp vụ

| Thuật ngữ | Cách hiểu trong dự án |
| --- | --- |
| Museum | Bảo tàng được quản lý trong hệ thống. |
| Building | Tòa nhà thuộc cấu trúc không gian của bảo tàng. |
| Floor | Tầng trong tòa nhà. |
| Gallery | Phòng hoặc khu trưng bày. |
| Artifact | Hiện vật. |
| Exhibit | Vật hoặc hiện vật được trưng bày; không mặc nhiên là một thực thể khác với Artifact. |
| Theme | Chủ đề dùng để phân loại hiện vật. |
| Exhibition | Triển lãm; cần xác nhận việc quản lý như một đối tượng nghiệp vụ độc lập. |
| Tour | Lộ trình tham quan gồm danh sách hiện vật có thứ tự. |
| Lượt tham quan | Một lần khách thực hiện tour, có thời gian và tiến độ riêng. |
| Gói dịch vụ hoặc pass | Quyền sử dụng hướng dẫn số của tài khoản sau khi mua. |

## 3. Người sử dụng và phân quyền

Hệ thống có đúng ba vai trò: **admin, staff và user**. Mỗi tài khoản chỉ có một vai trò tại một thời điểm.

| Vai trò | Trách nhiệm nghiệp vụ chính |
| --- | --- |
| Admin | Quản trị hệ thống, tài khoản và quyền truy cập; quản lý hoặc giám sát gói dịch vụ, giao dịch, quy tắc hoàn tiền và báo cáo. |
| Staff | Quản lý thông tin hiện vật, media và thuyết minh; tham gia kiểm duyệt nội dung; phản hồi đánh giá trong phạm vi công việc được giao. |
| User | Nhận diện và tìm hiểu hiện vật; sử dụng tour, chatbot, quiz; tích điểm và nhận huy hiệu; mua dịch vụ; xem lịch sử và gửi đánh giá. |

Nhân viên có thể được phân công phụ trách riêng một số phòng/khu, hiện vật hoặc triển lãm. Quyền thao tác phải xét cả vai trò và phạm vi được phân công. Ma trận quyền chi tiết, quyền duyệt nội dung và việc một nhân viên có thể làm việc tại nhiều bảo tàng vẫn cần được chốt.

## 4. Quản lý bảo tàng và hiện vật

### 4.1. Cấu trúc không gian

Cấu trúc không gian gồm **bảo tàng → tòa nhà → tầng → phòng/khu trưng bày**. Hiện vật không bắt buộc phải thuộc một phòng/khu. Khi hiện vật được chuyển sang vị trí khác, hệ thống không cần quản lý lịch sử vị trí.

Bản đồ chỉ cần thể hiện vị trí hiện vật. Chưa có yêu cầu xây dựng mạng lưới đường đi, thuật toán tìm đường trong nhà hoặc dẫn đường theo từng bước. Chức năng hỗ trợ lộ trình dựa trên danh sách hiện vật có thứ tự và vị trí hiển thị trên bản đồ.

### 4.2. Hiện vật và chủ đề

- Nhân viên quản lý thông tin, hình ảnh, media và nội dung thuyết minh của hiện vật.
- Một hiện vật có thể thuộc nhiều chủ đề.
- Chủ đề chỉ dùng để phân loại hiện vật; không mặc nhiên dùng chung cho tour hoặc triển lãm.
- Theo câu trả lời hiện tại, một hiện vật có một mã QR và một ảnh tham chiếu phục vụ nhận diện. Ảnh tham chiếu không đồng nghĩa với toàn bộ thư viện media của hiện vật.
- Khách có thể tìm kiếm hiện vật theo từ khóa, phòng/khu và chủ đề; duyệt hoặc chọn hiện vật từ bản đồ và danh sách.

### 4.3. Triển lãm

Người dùng đã nêu quy tắc có điều kiện: **nếu triển lãm được quản lý như một đối tượng riêng**, một hiện vật có thể tham gia nhiều triển lãm theo thời gian, không cần lưu thời gian tham gia của từng hiện vật và một triển lãm có thể sử dụng nhiều phòng/khu.

Cần phân biệt triển lãm với từ “Exhibit”, vì Exhibit đã được xác định là hiện vật được trưng bày. Việc đưa Exhibition thành một thực thể độc lập cần được xác nhận khi chốt mô hình dữ liệu.

## 5. Nhận diện và ghi nhận tham quan

Hệ thống hỗ trợ quét QR, nhận diện bằng hình ảnh và lựa chọn hiện vật từ bản đồ hoặc danh sách. **Quét QR là điều kiện ghi nhận khách đã tham quan hiện vật.** Việc nhận diện bằng ảnh hoặc mở trang thông tin không tự động được xem là đã tham quan theo yêu cầu hiện tại.

Cần phân biệt hai loại dữ liệu:

- **Lịch sử nhận diện:** lưu các lần nhận diện của khách để tra cứu hoạt động.
- **Trạng thái đã tham quan:** với mỗi cặp khách–hiện vật, chỉ giữ lần tham quan gần nhất khi khách xem lại nhiều lần.

Hai yêu cầu này cùng tồn tại: cập nhật lần tham quan gần nhất không đồng nghĩa với xóa lịch sử nhận diện.

## 6. Nội dung thuyết minh và AI

### 6.1. Thuyết minh đa ngôn ngữ

Hệ thống cung cấp thuyết minh đa ngôn ngữ, với tiếng Việt và tiếng Anh là các ví dụ trong đề xuất. Danh sách ngôn ngữ triển khai chính thức chưa được chốt.

Khách được chọn bài thuyết minh theo **độ dài** và **độ chi tiết**. Đây là hai tiêu chí riêng; không phân loại bài thuyết minh theo độ tuổi. Các mức cụ thể như ngắn/vừa/dài hoặc tổng quan/chuyên sâu cần được định nghĩa trong đặc tả chi tiết.

Chức năng audio narration được giữ trong phạm vi dịch vụ. Công nghệ tạo giọng nói và phương thức lưu hoặc sinh audio chưa được quyết định.

### 6.2. Chatbot và nguồn tri thức

- Chatbot giải thích hiện vật và trả lời các câu hỏi tiếp nối của khách.
- Một cuộc hội thoại có thể trao đổi về nhiều hiện vật.
- Lưu cuộc hội thoại và từng tin nhắn để khách xem lại.
- Quản lý tài liệu và nguồn thông tin phục vụ AI.
- Câu trả lời trực tiếp không cần nhân viên duyệt từng lần, nhưng phải dựa trên lượng thông tin đã được nhân viên phê duyệt.

Việc lưu liên kết giữa câu trả lời và phiên bản tài liệu nguồn là định hướng thiết kế phù hợp để hỗ trợ kiểm tra chất lượng và truy xuất, cần được đặc tả khi triển khai.

### 6.3. Kiểm duyệt và phiên bản

Quy trình kiểm duyệt áp dụng cho tất cả các loại nội dung được quản lý và xuất bản, gồm thông tin, media, thuyết minh, bản dịch và nội dung quiz. Cần giữ bản cũ cùng lịch sử người tạo, người duyệt.

Khi một bản sửa đổi đang chờ duyệt, khách tiếp tục xem bản đã xuất bản. Không ghi đè bản đang phục vụ khách bằng nội dung chưa được duyệt. Phản hồi chatbot trực tiếp tuân theo cơ chế sử dụng nguồn đã duyệt như mô tả ở trên.

Luồng biên tập dự kiến là: tạo hoặc chỉnh sửa → gửi duyệt → phê duyệt hoặc yêu cầu chỉnh sửa → xuất bản. Các trạng thái chi tiết và quyền chuyển trạng thái cần được xác định trong SRS.

## 7. Tour và lượt tham quan

### 7.1. Các loại tour

Hệ thống có cả tour mẫu do nhân viên tạo sẵn và tour cá nhân do AI gợi ý. Mỗi tour gồm danh sách hiện vật có thứ tự.

Lộ trình AI được lưu để khách mở lại và chỉnh sửa. Sở thích chỉ được chọn cho từng lần gợi ý, không phải thông tin sở thích cố định trong hồ sơ. Thời gian có sẵn là thông tin của từng lượt. Không có yêu cầu lưu bộ lựa chọn đầu vào để giải thích hoặc xem lại quá trình gợi ý.

### 7.2. Lượt thực hiện tour

Mỗi lần khách thực hiện một tour phải tạo một lượt tham quan riêng, lưu thời điểm bắt đầu, kết thúc và tiến độ. Cần phân biệt tour như một lộ trình với lượt tham quan như một lần sử dụng lộ trình đó.

Việc chỉnh sửa lộ trình không nên làm thay đổi lịch sử các lượt đã thực hiện. Quản lý phiên bản hoặc lưu bản chụp lộ trình là phương án thiết kế cần cụ thể hóa. Tiêu chí xác định hoàn thành tour, cách tính tiến độ và cách ghi nhận khách tự khám phá không chọn tour chưa được chốt.

## 8. Quiz, điểm và huy hiệu

### 8.1. Ngân hàng câu hỏi và lượt làm quiz

- Câu hỏi được tạo trước, sau đó nhân viên kiểm duyệt để đưa vào ngân hàng.
- Một quiz chỉ thuộc một hiện vật.
- Một câu hỏi có thể được sử dụng trong nhiều quiz.
- Mỗi lượt làm quiz chỉ đưa ra khoảng **2–3 câu hỏi**.
- Sau khi trả lời, khách có tùy chọn reset để nhận câu hỏi mới.
- Lưu cả kết quả tổng hợp và chi tiết từng câu trả lời.
- Cung cấp phản hồi tức thời cho khách sau khi trả lời.

Reset cần tạo lượt làm mới và bảo toàn kết quả cũ. Kết quả nên gắn với nội dung câu hỏi và đáp án tại thời điểm làm, để việc biên tập câu hỏi về sau không thay đổi lịch sử. Cách chọn câu hỏi mới và xử lý khi ngân hàng không đủ câu chưa được chốt.

### 8.2. Điểm tích lũy

Điểm được cộng từ hai loại hoạt động: quét hiện vật và trả lời đúng câu hỏi. Điểm tích lũy trên tài khoản, không chỉ tồn tại trong một lượt tham quan.

Chưa có quyết định về số điểm cụ thể, giới hạn nhận điểm, hoặc việc quét lại và trả lời lại có tiếp tục được cộng điểm không. Những quy tắc này phải được xác định trước khi triển khai chức năng tính điểm.

### 8.3. Huy hiệu

Mỗi tài khoản chỉ nhận một huy hiệu cụ thể một lần. Ví dụ, khi đạt điều kiện quét 10 hiện vật, khách được nhận huy hiệu tương ứng và không nhận lại chính huy hiệu đó.

Phạm vi đếm theo từng bảo tàng hay toàn hệ thống và yêu cầu 10 hiện vật khác nhau cần được xác nhận trong quy tắc huy hiệu.

## 9. Dịch vụ trả phí và thanh toán

### 9.1. Sản phẩm được bán

Hệ thống bán **quyền sử dụng hướng dẫn số**, không bán vé vào cửa theo yêu cầu hiện tại. Khách mua một tour và được sử dụng trong một ngày. Không có thuê bao theo tháng hoặc theo năm.

Một gói mở toàn bộ dịch vụ theo phạm vi được mua. Mỗi tài khoản mua gói cho chính mình, không mua hộ người khác. Cụm “toàn bộ dịch vụ” và mốc bắt đầu một ngày sử dụng vẫn cần được định nghĩa chính xác.

Thông tin cơ bản miễn phí vẫn thuộc phạm vi đề xuất. Cần có danh sách cụ thể chức năng miễn phí và chức năng yêu cầu quyền trả phí.

### 9.2. Đơn mua và giao dịch

- Tích hợp cổng thanh toán trực tuyến; nhà cung cấp cụ thể chưa được chọn.
- Nếu thanh toán thất bại, khách có thể thử lại.
- Lưu tất cả các lần giao dịch, bao gồm các lần thất bại.
- Quản lý quyền sử dụng đã mua, lịch sử giao dịch và hóa đơn.
- Cung cấp báo cáo hoặc dashboard doanh thu cho quản trị viên.

Đơn mua, lần thử thanh toán và quyền sử dụng cần được phân biệt. Một đơn có thể phát sinh nhiều lần thử thanh toán, nhưng việc xử lý thông báo lặp từ cổng thanh toán không được cấp trùng quyền sử dụng.

### 9.3. Hoàn tiền và hóa đơn

Hệ thống hỗ trợ hoàn tiền theo tỷ lệ phần trăm dựa trên quy tắc do chủ hệ thống đặt ra. Cần lưu quy tắc áp dụng và kết quả hoàn thực tế. Điều kiện được hoàn, cách tính tỷ lệ và tác động đến quyền sử dụng chưa được chốt.

Hóa đơn có đầy đủ thông tin người mua và thông tin giao dịch. Mẫu hóa đơn, thông tin bên bán, thuế và yêu cầu tích hợp hóa đơn điện tử cần được đặc tả riêng; câu trả lời hiện tại chưa xác định các nội dung này.

## 10. Đánh giá và phản hồi

Khách chỉ được gửi đánh giá **sau khi hoàn thành tour**. Các đối tượng đánh giá gồm:

- Thông tin được hệ thống cung cấp.
- Tour do hệ thống gợi ý.
- Chatbot.
- Trải nghiệm chung.

Hệ thống lưu phản hồi của nhân viên đối với đánh giá. Chưa chốt số lần đánh giá cho mỗi đối tượng, thang điểm, khả năng chỉnh sửa đánh giá và cách liên kết phản hồi với từng lượt tham quan.

## 11. Dữ liệu, nhật ký và báo cáo

Định hướng là lưu dữ liệu chi tiết để hỗ trợ tra cứu và phân tích. Các nhóm dữ liệu chính gồm:

| Nhóm | Nội dung cần quản lý |
| --- | --- |
| Bảo tàng và hiện vật | Cấu trúc không gian, hiện vật, chủ đề, vị trí hiện tại và thông tin triển lãm nếu được xác nhận. |
| Tài khoản | Vai trò, trạng thái tài khoản và phạm vi phân công nhân viên. |
| Nội dung | Nội dung đa ngôn ngữ, các mức thuyết minh, media, tài liệu nguồn, phiên bản và lịch sử duyệt. |
| Tour | Tour mẫu, lộ trình AI đã lưu, thứ tự hiện vật, các lượt tham quan và tiến độ. |
| Nhận diện | Lịch sử nhận diện và lần tham quan gần nhất của mỗi khách với mỗi hiện vật. |
| AI | Hội thoại, tin nhắn và dữ liệu phục vụ kiểm tra nguồn tri thức. |
| Quiz và gamification | Ngân hàng câu hỏi, lượt làm, từng câu trả lời, kết quả tổng hợp, điểm và huy hiệu. |
| Thương mại | Gói dịch vụ, đơn mua, quyền sử dụng, các lần thanh toán, hoàn tiền và hóa đơn. |
| Phản hồi và quản trị | Đánh giá, phản hồi của nhân viên và nhật ký các thao tác quan trọng. |

Các chỉ số có thể xây dựng từ dữ liệu này gồm doanh thu, giao dịch thất bại, tiền hoàn, mức sử dụng tour, tiến độ hoàn thành, hiện vật được quan tâm, kết quả quiz và phản hồi của khách. Ngoại trừ yêu cầu dashboard doanh thu trong đề xuất, danh sách chỉ số chi tiết cần được thống nhất thêm.

Yêu cầu lưu chi tiết không làm thay đổi các giới hạn đã xác nhận: không cần quản lý lịch sử vị trí hiện vật; không cần lưu lịch sử đầu vào gợi ý tour; trạng thái đã tham quan chỉ giữ lần gần nhất. Chính sách lưu giữ, xóa và ẩn dữ liệu chưa được quyết định.

## 12. Yêu cầu phi chức năng từ đề xuất

Các yêu cầu sau được giữ theo tài liệu ban đầu, chưa có chỉ tiêu định lượng bổ sung:

- **Dễ sử dụng:** giao diện di động thuận tiện cho khách tham quan và phù hợp khi sử dụng tại bảo tàng.
- **Tin cậy:** các chức năng thực hiện nhất quán, dữ liệu tiến độ và giao dịch được xử lý chính xác.
- **Hiệu năng:** thuyết minh và AI phản hồi đủ nhanh để phục vụ trải nghiệm tại chỗ.
- **Kết nối hạn chế:** hỗ trợ tình huống mạng yếu hoặc gián đoạn, chẳng hạn cache nội dung quan trọng. Chưa xác định chức năng nào được sử dụng hoàn toàn ngoại tuyến.
- **Bảo mật:** xác thực người dùng, kiểm soát quyền theo vai trò và phạm vi công việc, bảo vệ dữ liệu khách.
- **Thanh toán an toàn:** xử lý qua cổng tin cậy; không lưu thông tin thẻ hoặc ngân hàng thô.
- **Độ chính xác:** nội dung di sản và câu hỏi phải được kiểm duyệt; chất lượng AI cần được đánh giá bằng tiêu chí phù hợp.

Khi mở rộng lên nhiều bảo tàng, cần xác định rõ quyền truy cập dữ liệu giữa các bảo tàng. Nền tảng kỹ thuật, mô hình AI, công nghệ nhận diện, cơ sở dữ liệu và cổng thanh toán hiện chưa được lựa chọn chính thức.

## 13. Luồng nghiệp vụ chính

### 13.1. Chuẩn bị nội dung

1. Nhân viên được phân công quản lý đối tượng phù hợp.
2. Nhân viên nhập thông tin, tài liệu nguồn, media hoặc tạo nội dung bằng AI.
3. Nội dung được gửi kiểm duyệt và ghi nhận người tạo, người duyệt.
4. Nội dung được phê duyệt và xuất bản để phục vụ khách.
5. Khi sửa đổi, giữ bản cũ đang xuất bản trong thời gian bản mới chờ duyệt.

### 13.2. Tham quan và tương tác

1. Khách đăng nhập và truy cập bảo tàng muốn tham quan.
2. Khách chọn tour mẫu hoặc cung cấp sở thích, thời gian để AI gợi ý lộ trình.
3. Lộ trình AI được lưu và có thể chỉnh sửa.
4. Khách mua quyền dịch vụ khi sử dụng chức năng trả phí.
5. Hệ thống tạo lượt tham quan riêng khi khách thực hiện tour.
6. Khách quét QR để ghi nhận hiện vật đã tham quan, xem hoặc nghe thuyết minh và trao đổi với chatbot.
7. Khách làm quiz ngắn, nhận điểm và huy hiệu nếu đủ điều kiện.
8. Hệ thống ghi nhận tiến độ; sau khi hoàn thành tour, khách được gửi đánh giá.

### 13.3. Thanh toán và hoàn tiền

1. Khách chọn tour hoặc gói dịch vụ cho tài khoản của mình.
2. Hệ thống tạo đơn mua và thực hiện thanh toán qua cổng tích hợp.
3. Nếu thất bại, lưu lần giao dịch đó và cho phép thử lại.
4. Khi thanh toán hợp lệ, cấp quyền sử dụng và lập hóa đơn theo quy trình được thống nhất.
5. Nếu phát sinh hoàn tiền, áp dụng quy tắc tỷ lệ phần trăm và ghi nhận kết quả xử lý.

## 14. Các điểm cần xác nhận trước khi chốt đặc tả

| Vấn đề | Thông tin còn thiếu |
| --- | --- |
| Một ngày sử dụng | Là 24 giờ liên tục, một ngày theo lịch hay ngày khách chọn? Bắt đầu từ thanh toán, kích hoạt hay lần tham quan đầu tiên? |
| Phạm vi full dịch vụ | Áp dụng cho tour đã mua hay toàn bộ nội dung của bảo tàng? Có bao gồm triển lãm đặc biệt không? |
| Ranh giới miễn phí và trả phí | Những chức năng và mức nội dung nào được dùng miễn phí sau khi đăng nhập? |
| Quyền mua và thực hiện tour | Tour AI có mua giống tour mẫu không? Một quyền sử dụng cho phép bao nhiêu lượt tham quan? Sửa tour sau khi mua xử lý thế nào? |
| Triển lãm | Có chính thức quản lý Exhibition độc lập không? |
| Dữ liệu nhiều bảo tàng | Hiện vật, tour, chủ đề và nhân viên có được dùng hoặc quản lý xuyên bảo tàng không? |
| Kiểm duyệt | Ai được duyệt, có được tự duyệt không và lộ trình AI cá nhân được áp dụng quy trình duyệt như thế nào? |
| Nội dung đa ngôn ngữ | Danh sách ngôn ngữ, số mức độ dài, số mức độ chi tiết và cơ chế tạo audio. |
| Hoàn thành tour | Phải quét tất cả hiện vật hay đạt tỷ lệ nhất định? Khách có được kết thúc sớm không? |
| Tự khám phá | Khách không chọn tour có lượt tham quan riêng không và có được đánh giá trải nghiệm không? |
| Quiz | Loại câu hỏi, thời điểm cho reset, cách tránh lặp câu và xử lý khi không đủ 2–3 câu mới. |
| Điểm và huy hiệu | Điểm mỗi hoạt động, giới hạn cộng lại, phạm vi đếm và tiêu chí đạt huy hiệu. |
| Hoàn tiền | Điều kiện, thời hạn, tỷ lệ, cách duyệt và trạng thái quyền sử dụng sau khi hoàn. |
| Hóa đơn | Mẫu thông tin, chủ thể bán dịch vụ, thuế và tích hợp hóa đơn điện tử nếu có. |
| Đánh giá | Thang điểm, số lần đánh giá, quyền sửa hoặc xóa và đối tượng cụ thể của mỗi đánh giá. |
| Nhật ký và dữ liệu | Danh mục sự kiện cần lưu, thời hạn giữ dữ liệu, chính sách xóa/ẩn và chỉ số báo cáo. |

Các giả định trong bản ERD trước, như hiệu lực 24 giờ từ lúc kích hoạt, gói chỉ áp dụng cho phiên bản tour đã mua hoặc tour chỉ chứa hiện vật của một bảo tàng, cần được đối chiếu với các quyết định trên trước khi xem là yêu cầu chính thức.
