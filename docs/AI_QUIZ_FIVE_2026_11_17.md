# Xưởng AI — bộ 5 câu hỏi và đối chiếu Space

## Luồng UI thực tế

Đọc `smgs_web/src/components/ai_studio/AIContentStudio.jsx`, `src/services/staffAiApi.js` và `src/components/curation/QuestionBank.jsx`:

- Museum Staff/Admin chọn hiện vật, nguồn, độ khó và số lượng 1/3/5.
- Một lần bấm tạo trên FE hiện gọi BE `/api/artifacts/{id}/ai/drafts` tuần tự. Mỗi request nhận một câu và truyền `excludeQuestions` gồm các câu đã có. BE tiếp tục chịu trách nhiệm quyền truy cập và nguồn từ DB.
- FE ghép danh sách, cho chỉnh sửa, chuyển sang Ngân hàng câu hỏi. Ngân hàng hiện có nút lưu tất cả hoặc chỉnh sửa từng câu; lưu vẫn là bản nháp, không tự duyệt/xuất bản.

## Đã sửa

- Mặc định chọn 5 thay vì 1. Giữ lựa chọn 1 và 3.
- Không nhận câu hỏi lặp sau chuẩn hóa NFC, khoảng trắng và chữ hoa/thường. Đây là kiểm tra trùng văn bản, chưa phải phát hiện trùng ý nghĩa.
- Khi chỉ tạo được 2/5 câu, giữ hai câu và ghi bộ chưa hoàn tất kèm lỗi thực tế. Bỏ thông báo không có căn cứ rằng nguồn đã được khai thác tối đa.
- Hủy request giải phóng trạng thái busy để có thể chạy tiếp. Bỏ ước tính cố định 50 giây/câu và các nhãn ngụ ý AI đã kiểm chứng niên đại/thẩm định ngữ nghĩa.

## Phân biệt UI SMGS và demo HF

Bản Space mới trong `AI-System/deploy/huggingface/gradio-quiz` mặc định tạo bộ 5 trong một lần cấp GPU. Có API batch `/api/v1/studio/quiz-sets` nhưng BE/FE **chưa gọi endpoint batch này**. API `/api/v1/studio/drafts` vẫn trả một câu, phù hợp vòng lặp FE hiện có. Không tuyên bố rằng bộ 5 trên FE hiện chỉ dùng một lần cấp GPU. ZeroGPU quota/hàng đợi có thể làm bộ dừng giữa chừng.

Nếu muốn tối ưu FE thành một HTTP request và một lần cấp GPU cho cả bộ, cần bổ sung gateway batch ở BE và adapter FE tương ứng; chưa triển khai trong thay đổi này. Không đưa HF token hoặc service key vào FE.

## Kiểm chứng

Playwright Edge headless với API fixtures (không dùng model/DB thật):

```powershell
cd D:\SEP409\FrontEnd\smgs_web
npm run test:e2e -- e2e/backend-flows.spec.js --grep "AI quiz suggestions|defaults to five|partial quiz output|cancelling a quiz" --workers=1
npm run build
```

4/4 ca qua: chỉnh sửa/lưu một câu; mặc định năm câu, đủ exclusions và lưu tất cả thành draft; chỉ 2/5 câu với lỗi quota; hủy và mở khóa cấu hình. Build production qua. Các test fixture này không chứng minh chất lượng Qwen thật hoặc BE-to-HF đã hoạt động.

Test cũ có locator không còn khớp nhãn Ngân hàng câu hỏi (heading nay có số câu, tên nút đã đổi); đã cập nhật locator theo UI đang có. Ca bộ năm câu cần chờ lâu hơn 5 giây do luồng hiện nghỉ 1,5 giây giữa các request. Log lần thử đầu vẫn giữ tại `D:/SEP409/tmp/fe-five-quiz-e2e*.log`; kết quả cuối tại `D:/SEP409/tmp/fe-five-quiz-e2e-verified.log`.
