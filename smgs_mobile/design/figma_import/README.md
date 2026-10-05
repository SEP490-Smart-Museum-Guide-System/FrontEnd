# Bộ màn hình SMGS cho Figma

Mở `index.html` qua máy chủ xem trước để duyệt 46 màn hình: 27 màn hình khách tham quan, 6 màn hình kiểm duyệt viên, 6 màn hình nhân viên bảo tàng và 7 màn hình quản trị viên. Các bản vẽ SVG dùng màu và font của ứng dụng Flutter hiện tại. `manifest.json` liệt kê vai trò, tên màn hình và tên tệp.

```powershell
cd D:\SEP409\FrontEnd\smgs_mobile
node design\figma_import\serve.cjs
```

Mở `http://127.0.0.1:8091/` để xem toàn bộ. Chạy `node design\figma_import\generate.mjs` sau khi thay nội dung trong tập lệnh để tạo lại SVG.

File Figma đích: https://www.figma.com/design/xjD506Ua5BsbWAuSAk8Xnl/Untitled

Đã nhập đủ 46 bản vẽ vào file Figma ngày 04/10/2026. Mỗi màn có một frame riêng: 27 màn Khách tham quan, 6 màn Kiểm duyệt viên, 6 màn Nhân viên bảo tàng và 7 màn Quản trị viên. Những bảng ghép vẫn được giữ để xem nhanh toàn bộ vai trò. Do file Starter giới hạn ba trang, Nhân viên và Quản trị cùng nằm trên trang `Nhân viên & Quản trị · Web`. Các SVG được Figma chuyển thành chữ và vector có thể chỉnh sửa; đây là bản thiết kế tham khảo theo hệ màu ứng dụng, chưa phải component library.

Prototype trong Figma có flow `Tham quan · Đăng nhập → khám phá`. Nhấp vào frame để đi theo tuyến Đăng nhập → Trang chủ → Khám phá → Chi tiết bảo tàng → Bắt đầu khám phá → Quét mã → Chi tiết hiện vật → 3D → AI → Thuyết minh → Thử tài → Kết quả → Chọn hành trình → Lộ trình → Hoàn thành → Hồ sơ → Lịch sử → Chi tiết chuyến đi → Vé → Thanh toán mô phỏng. Các bước đã nối dùng Smart Animate 300 ms. Đây là tương tác ở cấp frame để duyệt nhanh bản thiết kế; chưa có hotspot theo từng nút, logic biểu mẫu, hoặc liên kết sau màn thanh toán.

`combine.mjs` tạo bốn bảng SVG từ `manifest.json` để nhập nhiều màn trong một thao tác; chạy `node design\figma_import\combine.mjs` nếu nội dung màn thay đổi.
