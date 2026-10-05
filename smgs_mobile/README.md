# SMGS · Ứng dụng khách tham quan

Ứng dụng Flutter này dành cho **Visitor (Khách tham quan)**. Ba vai trò còn lại của hệ thống — Admin, Museum Staff và System Staff — sử dụng cổng React + Vite tại `../smgs_web`.

Bản FE hiện dùng dữ liệu và đăng nhập mô phỏng, chưa nối backend. Tài khoản trải nghiệm của Visitor: `khach@smgs.vn` / `smgs123`; khách cũng có thể tạo tài khoản mô phỏng trong phiên.

## Chạy trên web khi chưa có simulator

```powershell
cd D:\SEP409\FrontEnd\smgs_mobile
flutter pub get
flutter run -d chrome
```

Kiểm tra bằng `flutter analyze` và `flutter test test/main_flows_test.dart`.
