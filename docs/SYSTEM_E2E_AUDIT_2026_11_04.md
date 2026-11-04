# Rà soát end-to-end toàn hệ thống SMGS — 04/11/2026

## Kết luận

**Đã có nhiều luồng nối FE với API BE trong source. Chưa có bằng chứng xác nhận một kịch bản hoàn chỉnh UI → BE thật → PostgreSQL thật → đọc lại trên UI trong lần rà soát này.**

Các test browser đang có xác nhận được FE và bộ phát audio, nhưng các API nghiệp vụ hoặc TTS trong test đều được thay bằng fixture. Không được dùng các kết quả đó để báo cáo toàn hệ thống, AI hoặc thanh toán thật đã hoàn tất end-to-end.

Mã được kiểm tra: FE `681ee13`, BE `870a94b`, AI-System `ed80ba5`. Không sửa nghiệp vụ hoặc dữ liệu DB trong lần rà soát này.

## Cách phân loại

| Mức | Ý nghĩa |
| --- | --- |
| Đã nối trong code | FE gọi endpoint thật, BE có controller/service/repository cho luồng đó. Chưa đồng nghĩa đã chạy thành công toàn luồng. |
| Đã kiểm thử FE | UI/client chạy với API fixture; kiểm tra hiển thị, request và xử lý phản hồi. |
| Đã kiểm thử tích hợp BE/DB | Phải thực sự chạy HTTP/service và PostgreSQL, không chỉ kiểm tra DTO/role hoặc mock repository. |
| Đã xác nhận E2E toàn luồng | Thao tác UI với API/DB thật, đăng nhập thật, ghi/đọc lại qua các vai trò liên quan; có bằng chứng kết quả và khôi phục dữ liệu kiểm thử. Nếu có AI/payment provider thì ghi rõ có gọi service thật hay không. |

## Ma trận nghiệp vụ

| Luồng | Trạng thái source | Bằng chứng hiện có / phần còn thiếu |
| --- | --- | --- |
| Đăng ký Visitor, đăng nhập, đăng xuất, lưu phiên và phân vai trò | Flutter/React đã nối auth API; BE có Identity/JWT và 5 role | Có test FE fixture, test logic auth/JWT BE, và mã test HTTP/DB. Live auth của FE hiện skip mặc định; chưa xác nhận UI→DB thật hôm nay. |
| Admin quản lý tài khoản, role và phân công | Có UI/API CRUD tài khoản, đổi role, active, assignment | Một test browser qua fixture; chưa xác nhận với JWT và DB thật qua UI. |
| Bảo tàng, tòa nhà/tầng/phòng, hiện vật, media, QR và cấu hình model | Có UI và API; FE không dùng mock nghiệp vụ làm fallback | Có test logic/contract/media; cần tạo/sửa/đọc lại bằng dữ liệu thật và kiểm tra scope chéo bảo tàng. |
| Museum Staff soạn nội dung → Curator duyệt → Visitor đọc published | Có chuỗi endpoint submit/manual, approve/reject, published và màn đọc ở Flutter | Là luồng cốt lõi đã nối trong source. Chưa chạy bằng ba tài khoản thật trên UI và kiểm tra version được lưu vào DB. |
| Câu hỏi → Curator duyệt → quiz published → Visitor làm bài → điểm/huy hiệu | FE/BE có ngân hàng câu hỏi, publish, daily quiz, attempt, đáp án và điểm | Test browser phần nghiệp vụ dùng fixture; BE ExperienceChecks hiện chỉ chạy nhánh không DB. Fixture DB Experience còn tham chiếu migration đã không còn trong source. |
| Tour published → bắt đầu visit → quét QR → tiến độ → hoàn thành | Có tour/visit/recognitions/progress/complete và UI Visitor | Test Flutter hiện dùng MockClient. BE có mã integration test nhưng chưa chạy với DB thật trong lần này. |
| Feedback sau visit → nhân viên trả lời/kiểm duyệt; Visitor gửi complaint → System Staff xử lý | Có API, state machine và UI theo role | BE validation/logic pass; chưa kiểm chứng các thao tác liên vai trò bằng UI/DB thật. |
| Resource/product → đơn → yêu cầu thanh toán → xác nhận → pass/invoice/revenue | Đã nối FE/BE cho đối soát thủ công; có vé nhóm và kiểm tra quyền | Chưa là thanh toán qua cổng bên ngoài. CommerceChecks hiện bị lỗi decimal validation, cần sửa trước khi chốt luồng thương mại. |
| Bản đồ trong bảo tàng, định vị theo QR, route theo visit | Có editor/publish, visitor map và route API | Có test graph/UI/request. Chưa xác nhận đầy đủ editor→DB→Visitor route trên bản đồ thật, với cùng revision và marker. |
| Bản đồ ngoài trời và chỉ đường | Có API khám phá/tuyến ngoài trời và mở Google Maps | Test provider hiện dùng HTTP handler fixture; live OSRM là nhánh tùy chọn. Không có bằng chứng mở đường tới bảo tàng thật từ UI trong lần rà soát này. |
| Bản thu published → audio player Flutter | Có tải audio và playback thật | Hai test Edge dùng WAV fixture, xác nhận giải mã/phát/pause/tua/rate/replay/cleanup thật trong browser. Chưa phải test lấy bản thu từ DB/media server thật. |
| Nội dung published → TTS tiếng Việt → nghe audio | FE đã có client và player thật; Python có Piper/sherpa-onnx | Chưa xác nhận chuỗi BE→Piper→audio thật; TTS local chưa chạy. Chi tiết ở TTS_REAL_AUDIO_2026_11_04.md. |
| Chụp ảnh thật → Vision → xác nhận hiện vật → đọc nội dung/ghi nhận | Python có nhận diện ONNX; FE có client và UI thử nghiệm | Chưa E2E: đường Flutter còn ảnh byte mẫu hoặc MockRecognitionService, parser candidates/health lệch service, chưa có gateway/quyền/ghi nhận ảnh đầy đủ. |
| Sinh thuyết minh/quiz, chat AI | Có UI/template và gợi ý mẫu | Chưa có API model sinh text/chat/RAG trong AI-System. Việc lưu một bản nháp mẫu vào BE không chứng minh AI generation thật. |
| Bộ ảnh → dựng 3D → Curator duyệt → model vào media BE → Visitor xem | Có scan service PoC và viewer/media API riêng | Chưa nối hết chuỗi: giới hạn ảnh lệch; model URL/auth và bước đưa scan output vào media BE còn thiếu. Xem audit AI. |
| Hoàn tiền, audit log, quyền giao dịch cho System Staff | FE báo chưa hỗ trợ ở các mục này | Chưa E2E; còn thiếu endpoint/quyền nghiệp vụ tương ứng. |
| Bookmark và cá nhân hóa tour theo sở thích | Bookmark lưu trong VisitStore phía client; BackendTourService chọn tour theo thời lượng | Chưa đồng bộ bookmark qua DB. Tham số interests chưa được dùng trong thuật toán chọn tour; chưa thể coi đây là cá nhân hóa AI theo sở thích. |
| Chọn bảo tàng hiển thị riêng trên bản đồ | UI adapter hiện suy ra từ isActive | Chưa có API bật/tắt hiển thị bản đồ độc lập; không nên báo hoàn thành đúng yêu cầu toggle riêng. |

## Kết quả kiểm tra thực tế trong lần này

### Môi trường và DB

- Kiểm tra socket local ở các cổng 5432, 5169, 8000, 8001, 8002, 8080 và 8090: không có kết nối được chấp nhận tại thời điểm rà soát.
- Chạy `SMGS.IndoorMapChecks --inspect`, dùng cấu hình DB BE hiện tại và transaction READ ONLY: **thất bại do không kết nối được 127.0.0.1:5432**, SocketException 10061.
- Không start API bằng cấu hình Development vì startup có seed; không chạy test ghi vào DB hiện hành, không tự sửa migration hoặc dữ liệu.
- Chưa kiểm tra môi trường Vercel/API/DB production; không suy diễn từ việc service local chưa chạy rằng production cũng lỗi.

### BE

Đã restore NuGet cần thiết, build Release solution thành công và chạy riêng cả 7 project không có `--database`/`--http`:

| Bộ kiểm tra | Kết quả |
| --- | --- |
| SMGS.AuthChecks | Pass: validation, Identity/password/JWT, DI và metadata. |
| SMGS.CommerceChecks | **Fail**: `0.01 is not a valid value for Decimal`. |
| SMGS.ContentChecks | Pass: quyền, nội dung/phiên bản, media/3D và review guards. |
| SMGS.DiscoveryChecks | Pass: discovery, geometry, validation và xử lý provider fixture. |
| SMGS.FeedbackChecks | Pass: visit/feedback/complaint validation và state machine. |
| SMGS.IndoorMapChecks | Pass: graph, routing, image decode và authorization. |
| SMGS.ExperienceChecks | Pass nhánh không DB: authorization/timezone/public contract. |

Các kết quả trên là kiểm tra logic/contract. Nhánh integration PostgreSQL và HTTP có DB không được thực thi thành công trong lần này.

### FE và AI

- Chạy lại Node test React: **19 pass, 1 live-auth test skip** do chưa đặt `SMGS_AUTH_TEST_BASE_URL`.
- Log kiểm thử FE gần nhất trên source đã tích hợp: **68 Flutter test pass, 1 live-auth skip**; **8 test browser nghiệp vụ pass với API fixture**; **2 test audio browser pass với WAV fixture**.
- Flutter live auth dùng cờ `RUN_LIVE_AUTH`; các test mới về visit/QR/navigation/feedback vẫn sử dụng MockClient.
- Chưa chạy inference Piper/Vision hoặc worker COLMAP thật trong lần này.

Log BE và DB của lần rà soát nằm tại `D:\SEP409\tmp\system-e2e-audit-20261104`, ngoài repository. Log FE cũ không được coi là lần chạy mới của toàn hệ thống.

## Những điểm đang ngăn việc chốt E2E

### 1. Decimal validation của ProductRequest

`BackEnd/Smart_Museum_Guide_System/SMGS.Application/DTOs/Commerce/CommerceDtos.cs:19` dùng `Range(typeof(decimal), "0.01", "999999999999")`.

CommerceChecks tái hiện được lỗi parse mức giá nhỏ nhất theo locale hiện tại, ngay ở bước validation trước khi truy cập DB. Vì API cũng dùng validation DTO này, luồng tạo/sửa product cần được kiểm tra lại theo locale triển khai. Cần cố định quy tắc culture cho validation và thêm kiểm thử locale phù hợp; không nên bỏ qua test hoặc chỉ dựa vào môi trường Linux có locale khác.

### 2. Lịch sử migration và fixture Experience chưa đồng bộ

- Migrations đang có: `20261031230249_AddVisitorExperience`, `20261101020257_InitialCreate`.
- AddVisitorExperience có SQL đọc bảng visits ngay đầu Up, nhưng thứ tự timestamp lại trước InitialCreate. Đây là vấn đề cần kiểm chứng trên DB trống trước khi coi setup/deploy DB mới là hoàn chỉnh.
- `tests/SMGS.ExperienceChecks/Program.cs` còn gọi `MigrateAsync("20261028090549_ConfirmProductValidityPolicy")`, migration không còn trong assembly hiện tại.

Chưa chạy migration trên DB thật để chứng minh kết quả; cần thống nhất baseline/nâng cấp dựa trên lịch sử DB thực tế. Không tự xóa lịch sử hoặc reset DB đang có dữ liệu.

### 3. CI hiện chưa chứng minh được tích hợp DB

Trong `BackEnd/.github/workflows/ci.yml`, CI build solution rồi chạy test bằng `--no-build`. Tuy nhiên:

- Solution thiếu 3 project được CI gọi: AuthChecks, ContentChecks, FeedbackChecks. Trên checkout sạch, lệnh build solution không tạo các binary đó.
- ExperienceChecks có trong solution nhưng thiếu trong danh sách test CI.
- CI chưa cấp PostgreSQL và không chạy `--database`/`--http`.

Cần sửa phạm vi build/test và thêm môi trường DB test riêng trước khi lấy CI làm bằng chứng tích hợp xuyên tầng. Lần audit này không kiểm tra trạng thái GitHub Actions remote.

### 4. Kiểm thử browser đang chặn API thật bằng fixture

`smgs_web/e2e/backend-flows.spec.js` dùng `page.route('**/api/**', ...)` và session token fixture. Các test này hữu ích cho FE nhưng không thể bắt lỗi DB, JWT thật hoặc khác biệt hợp đồng BE đã thay đổi.

`smgs_web/audio-e2e/narration.spec.js` cũng chặn request TTS bằng WAV kiểm thử. Nó xác nhận audio player thật, không xác nhận Piper thật.

### 5. README FE đã cũ

README gốc còn mô tả toàn bộ FE là mock, dẫn tới `mockData.js` đã không còn và giả định backend chưa nối. Đó không phải trạng thái source hiện tại. Khi cập nhật README, cần tách rõ luồng đã nối API, phần demo AI còn giữ và phần chưa kiểm thử DB/production.

## Các kịch bản nên xác nhận E2E trước

1. **Nội dung hiện vật:** Admin phân công → Museum Staff tạo hiện vật/nội dung manual → Curator duyệt → Visitor mở đúng bản published; sửa rồi duyệt lại và kiểm tra version đọc được sau reload.
2. **Hành trình tham quan:** tạo/publish tour → Visitor bắt đầu visit → quét QR thật → tiến độ tăng một lần với RequestId chống trùng → hoàn thành → feedback → Museum Staff trả lời → Visitor đọc lại.
3. **Quiz/điểm:** tạo câu hỏi → Curator duyệt/publish quiz → Visitor đủ điều kiện nhận daily quiz → làm/nộp → lịch sử và điểm/huy hiệu đọc lại từ DB; thử gửi lại để xác nhận không cộng trùng.
4. **Thương mại đối soát thủ công:** sửa lỗi validation → tạo resource/product → Visitor tạo đơn → manager xác nhận theo chứng từ test → pass/access/invoice/revenue; xác nhận lỗi/thu hồi/hết hạn và vé nhóm. Đây vẫn chưa phải thanh toán qua cổng bên ngoài.
5. **Giọng Việt:** bật TTS thật → lấy script published từ BE → tổng hợp Piper → phát/pause/tua trên Flutter web; ghi lại service/version và kết quả kiểm tra âm thanh.

Nên dùng DB test tách riêng, tài khoản của đủ 5 role và dữ liệu có mã nhận diện test; xác minh cả response lẫn bản ghi/đọc lại, rồi dọn dữ liệu test. Không dùng token hoặc response fixture cho bộ test E2E này.

## Câu mô tả tiến độ phù hợp

> Hệ thống đã tích hợp FE với các API nghiệp vụ cốt lõi như xác thực/phân quyền, quản lý hiện vật, kiểm duyệt nội dung, tour, QR, quiz, feedback và thương mại. Các bộ kiểm tra FE và phần lớn kiểm tra logic BE đã có; đang hoàn thiện kiểm thử end-to-end với DB thật, xử lý lỗi validation/migration và nối hoàn chỉnh các luồng AI/thanh toán ngoài hệ thống.
