# Bộ màn hình SMGS cho Figma

Mở `index.html` qua máy chủ xem trước để duyệt 46 màn hình: 27 màn hình khách tham quan, 6 màn hình kiểm duyệt viên, 6 màn hình nhân viên bảo tàng và 7 màn hình quản trị viên. Các bản vẽ SVG dùng màu và font của ứng dụng Flutter hiện tại. `manifest.json` liệt kê vai trò, tên màn hình và tên tệp.

```powershell
cd D:\SEP409\FrontEnd\smgs_mobile
node design\figma_import\serve.cjs
```

Mở `http://127.0.0.1:8091/` để xem toàn bộ. Chạy `node design\figma_import\generate.mjs` sau khi thay nội dung trong tập lệnh để tạo lại SVG.

File Figma đích: https://www.figma.com/design/xjD506Ua5BsbWAuSAk8Xnl/Untitled

Hiện file đã có trang khách tham quan, kiểm duyệt viên và nhân viên bảo tàng, cùng một màn hình đăng nhập được dựng thành các lớp Figma. Gói Starter đã hết lượt gọi Figma MCP và giới hạn ba trang, nên các SVG còn lại chưa được nhập. Khi nhập thủ công, có thể đặt các màn hình quản trị ở phần riêng trong trang thứ ba; nếu nâng gói thì tạo trang thứ tư sẽ rõ ràng hơn. SVG là bản vẽ vector để xem và nhập, không chứa tương tác hoặc animation của Flutter.
