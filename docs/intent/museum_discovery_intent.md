# Statement of Intent: Museum Discovery & Outdoor Navigation

**Project:** Smart Museum Guide System (SMGS)  
**Target Application:** Mobile Flutter (`smgs_mobile`)  
**Date Confirmed:** 20/10/2026  
**Status:** Confirmed & Approved

---

## 1. Core Intent
- **Outcome:** Bản Kế hoạch Triển khai Kỹ thuật & Khớp nối API chi tiết (Implementation Plan & Task Breakdown) cho tính năng Museum Discovery & Outdoor Navigation trên ứng dụng Mobile Flutter (`smgs_mobile`).
- **User:** Frontend Mobile Developer và các thành viên nhóm dự án Capstone / Backend Developer để đối soát và triển khai song song.
- **Why now:** Phía Backend ASP.NET Core đã hoàn thành và bàn giao tài liệu kỹ thuật (`Museum_Discovery_API.md` ngày 19/10/2026); yêu cầu tại Mục 8 của `Map.txt` bắt buộc phải phân tích kỹ codebase và lập kế hoạch trước khi viết code.
- **Success:** Kế hoạch phân rã chi tiết từng giai đoạn (Dependencies & Permissions -> Data Layer / API Service -> Map Discovery UI -> Route Preview -> Deep Link Navigation) khớp 100% với hợp đồng API Backend, có giải pháp dự phòng an toàn khi thiết bị chưa có Google API Key.
- **Constraint:** Chưa viết code cho đến khi kế hoạch được duyệt; không can thiệp hệ thống Auth/JWT hiện có; giữ vững bản sắc Curatorial Heritage (`#F4EBDD`, `#6B2E2E`, `#B38B59`).
- **Out of scope:** Dẫn đường rẽ từng chặng (turn-by-turn) trong Flutter, điều hướng trong nhà (Indoor Navigation), GPS tracking liên tục, lưu lịch sử GPS của du khách.

---

## 2. Technical Alignment Summary
1. **Backend Integration:**
   - `GET /api/museums`: Phân trang, tìm kiếm `keyword`, lọc `cityCode` (mã 2 số, ví dụ `79` cho TP.HCM), sắp xếp `sortBy=distance` kèm cặp `latitude` & `longitude`.
   - `GET /api/museums/cities`: Danh mục 34 tỉnh/thành phố chuẩn theo QĐ 19/2025/QĐ-TTg.
   - `POST /api/navigation/outdoor/routes`: Nhận tọa độ xuất phát, ID bảo tàng, `travelMode` (`DRIVE`, `TWO_WHEELER`, `WALK`), trả về `distanceMeters`, `durationSeconds`, `encodedPolyline`, và `warning`.
2. **Mobile Architecture:**
   - Package: `google_maps_flutter`, `geolocator`, `flutter_polyline_points`, `http`.
   - Architecture pattern: Clean separation (Model DTO -> Repository/Service -> State/Controller -> Presentation UI).
   - Mock & Safe Mode: Sẵn sàng chế độ Mock/Fallback preview khi chưa có API key thực tế trên máy thử nghiệm.
