# Cổng Giám tuyển SMGS

Website này tách riêng cho role **Curator/Giám tuyển**. Curator chỉ xử lý nội dung thuộc bảo tàng được phân công: xem xét, hiệu đính, yêu cầu sửa, từ chối, phê duyệt và xuất bản thông tin hiện vật, bản dịch, thuyết minh và quiz AI.

## Chạy cục bộ

```powershell
cd smgs_curator
npm install
npm run dev
```

Tài khoản mô phỏng: `curator@smgs.vn / smgs123`.

## Deploy Vercel riêng

Tạo một Vercel Project mới từ cùng repository và đặt **Root Directory** là `smgs_curator`. Giữ Build Command là `npm run build`, Output Directory là `dist`.

Portal này không dùng chung runtime với `smgs_web`. Khi backend có API, hai portal sẽ dùng chung API xác thực/RBAC; backend phải trả về `museumId` của Curator để giới hạn dữ liệu theo bảo tàng được phân công.
