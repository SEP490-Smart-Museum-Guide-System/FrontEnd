# 🛠️ BACKEND CODE PATCH: TỰ ĐỘNG TẠO TÒA NHÀ CHÍNH & TẦNG TRỆT KHI TẠO BẢO TÀNG

> **Dành cho:** Backend Developer phụ trách dự án SMGS  
> **Nội dung:** Khi System Admin tạo bảo tàng mới, hệ thống tự động sinh 01 Tòa nhà mặc định (*Tòa nhà chính*) và 01 Tầng mặc định (*Tầng trệt*) trong cùng 1 Database Transaction theo quy định tại `Fix.txt` (Mục 3).

---

## 📌 Cách triển khai (Chỉ cần sửa 1 file duy nhất ở Infrastructure)

### File: `SMGS.Infrastructure/Repositories/MuseumRepository.cs`
**Vị trí:** Thay thế hàm `CreateAsync` (khoảng dòng 92–97).

### 📝 Đoạn mã trước khi sửa:
```csharp
public async Task<Museum> CreateAsync(Museum museum)
{
    db.Museums.Add(museum);
    await db.SaveChangesAsync();
    return museum;
}
```

### ✨ Đoạn mã sau khi sửa (Copy & Paste):
```csharp
public async Task<Museum> CreateAsync(Museum museum)
{
    // Bắt đầu một Database Transaction để đảm bảo tính toàn vẹn dữ liệu
    await using var transaction = await db.Database.BeginTransactionAsync();
    try
    {
        // 1. Lưu bản ghi Bảo tàng mới
        db.Museums.Add(museum);
        await db.SaveChangesAsync();

        // 2. Tự động tạo "Tòa nhà chính" mặc định thuộc bảo tàng vừa tạo
        var defaultBuilding = new Building
        {
            MuseumId = museum.Id,
            Name = "Tòa nhà chính"
        };
        db.Buildings.Add(defaultBuilding);
        await db.SaveChangesAsync();

        // 3. Tự động tạo "Tầng trệt" (Level 0) thuộc Tòa nhà chính
        var defaultFloor = new Floor
        {
            BuildingId = defaultBuilding.Id,
            LevelNo = 0,
            Name = "Tầng trệt"
        };
        db.Floors.Add(defaultFloor);
        await db.SaveChangesAsync();

        // 4. Hoàn tất toàn bộ giao dịch
        await transaction.CommitAsync();

        return museum;
    }
    catch
    {
        // Rollback toàn bộ nếu bất kỳ bước nào thất bại
        await transaction.RollbackAsync();
        throw;
    }
}
```

---

## 🔍 Giải thích kỹ thuật:
1. **Tính tương thích:** Không cần thay đổi interface `IMuseumRepository` hay `MuseumService.cs` vì hàm `CreateAsync(Museum museum)` giữ nguyên signature và kiểu trả về `Task<Museum>`.
2. **Nguyên tử (Atomicity):** Sử dụng `db.Database.BeginTransactionAsync()`. Nếu lưu Tòa nhà hoặc Tầng bị lỗi, bảo tàng cũng sẽ không được tạo dở dang (ngăn chặn tình trạng bảo tàng "mồ côi" không có cấu trúc).
3. **Cấu trúc sinh ra:**
   ```
   Bảo tàng mới (Id)
   └── Tòa nhà chính (MuseumId = Id)
       └── Tầng trệt (BuildingId = defaultBuilding.Id, LevelNo = 0)
   ```
4. **Không tạo sơ đồ hay phòng:** Theo đúng tài liệu `Fix.txt` mục 3.2, không tạo sẵn phòng trưng bày hay sơ đồ bản đồ; việc này sẽ do Museum Staff phụ trách thêm sau.
