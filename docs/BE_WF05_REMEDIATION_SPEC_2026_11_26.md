# TÀI LIỆU YÊU CẦU & ĐẶC TẢ KỸ THUẬT BACKEND (BE HANDOFF SPEC)
## BỔ SUNG CÁC TÍNH NĂNG CÒN THIẾU CHO WORKFLOW WF-05
**Dự án:** Smart Museum Guide System (FA26SE202)  
**Phụ trách Workflow WF-05:** Huỳnh Minh Tâm (FE)  
**Người nhận tài liệu:** Thành viên phụ trách Backend (`SMGS.API`, `SMGS.Infrastructure`)  
**Ngày lập:** 26/11/2026  
**Mục tiêu:** Bổ sung 100% các lỗ hổng kỹ thuật phía Backend để hoàn thiện tính năng **F15 (Support, Refund & Operational Monitoring)**, phục vụ buổi bảo vệ chính thức Review 2 / Defense 1.1 trước Hội đồng chấm thi.

---

## 1. BỐI CẢNH & LÝ DO CẦN BỔ SUNG (PROBLEM STATEMENT)

Đối chiếu với bản cam kết **BM04 Review 2**:
1. **F15 Acceptance Criteria:** *"Authorized staff can inspect support/refund and AI-quality incidents with an **auditable status history**."*
2. **Kịch bản Demo DS-05a & DS-05b:** *"Two museums; paid/pending/failed/refunded samples and visits... pending/refunded order not miscounted."*

### Hiện trạng kiểm toán Backend:
- ✅ **F13 (Báo cáo doanh thu) & F14 (Báo cáo tham quan):** Đã hoàn thiện 100% qua `CommerceController.Revenue` và `CommerceController.VisitReport`.
- ✅ **N03 (Cách ly dữ liệu bảo tàng):** Đã hoàn thiện 100% qua hàm `StaffAccess` (chặn 403 Forbidden).
- ✅ **F15 - Giám sát chất lượng AI:** Đã hoàn thiện 100% qua `GET /api/guide/logs`.
- ❌ **F15 - Khiếu nại (Complaints):** Entity `Complaint` hiện chỉ lưu trạng thái cuối cùng, **chưa có bảng lưu vết lịch sử thay đổi trạng thái (`auditable status history`)** $\rightarrow$ Vi phạm tiêu chí nghiệm thu BM04.
- ❌ **F15 - Hoàn tiền (Refunds):** BE mới chỉ có hàm `CancelOrder` do Khách (Buyer) tự gọi. **Chưa có API cho Nhân viên Hệ thống (System Staff / Admin) duyệt hoặc từ chối hoàn tiền** $\rightarrow$ Dẫn đến Frontend trên màn hình `SystemOperations.jsx` đang phải hiển thị thông báo lỗi: *"Chức năng hoàn tiền chưa được máy chủ hỗ trợ"*.

---

## 2. YÊU CẦU 1: BỔ SUNG LỊCH SỬ TRẠNG THÁI KIỂM TOÁN (`AUDITABLE STATUS HISTORY`)

### 2.1. Tạo Domain Entity mới: `ComplaintStatusHistory.cs`
* **Vị trí file:** `SMGS.Domain/Entities/ComplaintStatusHistory.cs`
* **Mã nguồn đề xuất:**
```csharp
namespace SMGS.Domain.Entities;

/// <summary>
/// Lưu vết kiểm toán lịch sử chuyển trạng thái của khiếu nại (F15 Auditable Status History).
/// </summary>
public class ComplaintStatusHistory
{
    public int Id { get; set; }

    /// <summary>Khóa ngoại liên kết tới Complaint.</summary>
    public int ComplaintId { get; set; }

    /// <summary>Trạng thái trước khi đổi (null nếu là lúc vừa tạo mới).</summary>
    public string? FromStatus { get; set; }

    /// <summary>Trạng thái mới sau khi đổi.</summary>
    public string ToStatus { get; set; } = string.Empty;

    /// <summary>ID của người thực hiện thay đổi (Staff hoặc Visitor).</summary>
    public Guid ChangedBy { get; set; }

    /// <summary>Ghi chú nội bộ hoặc biên bản xử lý tại thời điểm chuyển trạng thái.</summary>
    public string? Note { get; set; }

    /// <summary>Thời điểm ghi nhận (UTC).</summary>
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;

    // Navigation property (nếu cần)
    public virtual Complaint? Complaint { get; set; }
}
```

### 2.2. Đăng ký vào `ApplicationDbContext.cs`
* **Vị trí file:** `SMGS.Infrastructure/Data/ApplicationDbContext.cs`
* **Cần thêm:**
```csharp
public DbSet<ComplaintStatusHistory> ComplaintStatusHistories => Set<ComplaintStatusHistory>();

// Trong OnModelCreating:
builder.Entity<ComplaintStatusHistory>(entity =>
{
    entity.ToTable("complaint_status_histories");
    entity.HasKey(e => e.Id);
    entity.HasOne(e => e.Complaint)
          .WithMany()
          .HasForeignKey(e => e.ComplaintId)
          .OnDelete(DeleteBehavior.Cascade);
    entity.HasIndex(e => new { e.ComplaintId, e.ChangedAt });
});
```

### 2.3. Cập nhật DTOs
* **File:** `SMGS.Application/DTOs/Complaint/Response/ComplaintResponseDto.cs`
* **Thêm record DTO:**
```csharp
public record ComplaintStatusHistoryDto(
    int Id,
    int ComplaintId,
    string? FromStatus,
    string ToStatus,
    Guid ChangedBy,
    string? Note,
    DateTime ChangedAt
);

public record ComplaintResponseDto(
    int Id,
    Guid VisitorId,
    string Subject,
    string Body,
    string Status,
    Guid? AssignedTo,
    string? ResolutionNote,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    DateTime? ResolvedAt,
    IReadOnlyList<ComplaintStatusHistoryDto>? StatusHistories = null
);
```

### 2.4. Cập nhật Logic trong `ComplaintService.cs`
* **Vị trí file:** `SMGS.Application/Services/ComplaintService.cs`
1. **Khi tạo mới (`CreateAsync`):**
   Ghi thêm 1 bản ghi vào `db.ComplaintStatusHistories`:
   - `FromStatus = null`, `ToStatus = ComplaintStatus.New`, `ChangedBy = visitorId`, `Note = "Khách gửi yêu cầu hỗ trợ mới"`.
2. **Khi Staff tiếp nhận (`AssignToMeAsync`):**
   - `FromStatus = ComplaintStatus.New`, `ToStatus = ComplaintStatus.InProgress`, `ChangedBy = staffId`, `Note = "Nhân viên tiếp nhận xử lý"`.
3. **Khi Staff cập nhật trạng thái (`UpdateStatusAsync`):**
   - `FromStatus = complaint.Status`, `ToStatus = dto.Status`, `ChangedBy = staffId`, `Note = dto.ResolutionNote`.
4. **Khi trả về `GetByIdAsync` hoặc `GetAllAsync`:**
   Nạp kèm danh sách `ComplaintStatusHistories` theo thứ tự thời gian tăng dần `OrderBy(x => x.ChangedAt)` vào trường `StatusHistories`.

---

## 3. YÊU CẦU 2: BỔ SUNG API PHÊ DUYỆT / TỪ CHỐI HOÀN TIỀN (`REFUND EXECUTION & INSPECTION`)

Hiện tại `CommerceService.CancelOrder` đã có sẵn công thức tính hoàn tiền vào ví khách (`WalletTransactions`). Cần mở thêm API cho **System Staff / Admin** chủ động kiểm tra và thực hiện hoàn tiền theo hồ sơ hỗ trợ.

### 3.1. DTOs cần bổ sung
* **File:** `SMGS.Application/DTOs/Commerce/CommerceDtos.cs`
```csharp
public class ProcessRefundRequest
{
    [Required]
    public bool Approved { get; set; }

    /// <summary>
    /// Tỷ lệ hoàn tiền (0 - 100%).
    /// Nếu để trống (null), hệ thống sẽ tự tính theo chính sách thời gian (>=3 ngày: 100%, 2 ngày: 50%, <2 ngày: 0%).
    /// </summary>
    [Range(0, 100)]
    public decimal? OverridePercentage { get; set; }

    [Required, StringLength(1000, MinimumLength = 3)]
    public string Reason { get; set; } = string.Empty;

    /// <summary>ID khiếu nại liên kết nếu hoàn tiền theo hồ sơ hỗ trợ (optional).</summary>
    public int? ComplaintId { get; set; }
}

public record RefundExecutionResponse(
    Guid OrderId,
    bool Approved,
    decimal RefundedAmount,
    string Currency,
    string Status,
    string Message,
    DateTime ProcessedAt
);

public record RefundListItemDto(
    Guid OrderId,
    int MuseumId,
    string MuseumName,
    string BuyerName,
    decimal OriginalAmount,
    decimal RefundedAmount,
    string Currency,
    string Status,
    DateTime? CancelledAt,
    string? Reason
);
```

### 3.2. Bổ sung Controller Endpoints trong `CommerceController.cs`
* **Vị trí file:** `SMGS.API/Controllers/CommerceController.cs`

#### Endpoint 1: Xử lý duyệt / từ chối hoàn tiền
```csharp
/// <summary>
/// Nhân viên Hệ thống / Quản trị viên duyệt hoặc từ chối hoàn tiền cho đơn hàng (F15).
/// </summary>
[Authorize(Roles = $"{RoleNames.Admin},{RoleNames.Staff}")]
[HttpPost("orders/{orderId:guid}/refund")]
public async Task<IActionResult> ProcessRefund(
    Guid orderId,
    [FromBody] ProcessRefundRequest request)
{
    var staffId = UserId;
    var result = await service.ProcessRefund(orderId, staffId, request);
    return StatusCode(result.StatusCode, result);
}
```

#### Endpoint 2: Lấy danh sách các đơn hàng đã/đang yêu cầu hoàn tiền (Đối soát)
```csharp
/// <summary>
/// Lấy danh sách đơn hàng có hoàn tiền để đối soát (F13 & F15).
/// </summary>
[Authorize(Roles = $"{RoleNames.Admin},{RoleNames.Staff},{RoleNames.MuseumStaff}")]
[HttpGet("refunds")]
public async Task<IActionResult> GetRefunds(
    [FromQuery] int? museumId = null,
    [FromQuery] DateTime? from = null,
    [FromQuery] DateTime? to = null,
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 20)
{
    var result = await service.GetRefundList(museumId, from, to, page, pageSize, UserId, Admin);
    return StatusCode(result.StatusCode, result);
}
```

### 3.3. Hiện thực Logic trong `CommerceService.cs`
* **Vị trí file:** `SMGS.Infrastructure/Services/CommerceService.cs`

#### Logic phương thức `ProcessRefund`:
```csharp
public async Task<ResponseDto<RefundExecutionResponse>> ProcessRefund(
    Guid orderId,
    Guid staffId,
    ProcessRefundRequest request)
{
    await using var tx = await db.Database.BeginTransactionAsync();
    var order = await LockOrder(orderId);

    if (order.Status != "paid")
        return ResponseDto<RefundExecutionResponse>.Fail("Chỉ có thể hoàn tiền cho đơn hàng đã thanh toán (paid).", 400);

    if (order.RefundedAmount >= order.Amount)
        return ResponseDto<RefundExecutionResponse>.Fail("Đơn hàng này đã được hoàn toàn bộ tiền trước đó.", 409);

    if (!request.Approved)
    {
        // Từ chối hoàn tiền: Ghi log khiếu nại (nếu có) và thông báo cho khách
        if (request.ComplaintId.HasValue)
        {
            var complaint = await db.Complaints.FindAsync(request.ComplaintId.Value);
            if (complaint != null)
            {
                complaint.ResolutionNote = $"Từ chối hoàn tiền: {request.Reason}";
                complaint.Status = ComplaintStatus.Resolved;
                complaint.ResolvedAt = DateTime.UtcNow;
                // Ghi log status history
                db.ComplaintStatusHistories.Add(new ComplaintStatusHistory
                {
                    ComplaintId = complaint.Id,
                    FromStatus = ComplaintStatus.InProgress,
                    ToStatus = ComplaintStatus.Resolved,
                    ChangedBy = staffId,
                    Note = complaint.ResolutionNote,
                    ChangedAt = DateTime.UtcNow
                });
            }
        }
        await db.SaveChangesAsync();
        await tx.CommitAsync();

        return ResponseDto<RefundExecutionResponse>.Success(new RefundExecutionResponse(
            order.Id, false, 0, order.Currency, order.Status, "Đã từ chối hoàn tiền theo chính sách.", DateTime.UtcNow));
    }

    // 1. Tính toán tỷ lệ hoàn
    decimal rate;
    if (request.OverridePercentage.HasValue)
    {
        rate = request.OverridePercentage.Value / 100m;
    }
    else
    {
        // Tính tự động theo quy chế BM04: >= 3 ngày: 100%, 2 ngày: 50%, < 2 ngày: 0%
        var daysBefore = order.VisitDate.DayNumber - LocalToday().DayNumber;
        rate = daysBefore >= 3 ? 1.0m : daysBefore == 2 ? 0.5m : 0.0m;
    }

    var refundAmount = decimal.Round(order.Amount * rate, 2, MidpointRounding.AwayFromZero);
    if (refundAmount <= 0)
        return ResponseDto<RefundExecutionResponse>.Fail("Theo chính sách thời hạn tham quan, số tiền hoàn tính được là 0 đ.", 400);

    // 2. Cập nhật số tiền hoàn vào đơn hàng
    order.RefundedAmount += refundAmount;
    if (order.RefundedAmount >= order.Amount)
    {
        order.Status = "cancelled";
        order.CancelledAt = DateTime.UtcNow;

        // 3. Thu hồi vé nếu hoàn 100%
        var passes = await db.MuseumPasses.Where(p => p.OrderId == order.Id && p.RevokedAt == null).ToListAsync();
        foreach (var pass in passes)
        {
            pass.RevokedAt = DateTime.UtcNow;
        }
    }

    // 4. Cộng tiền hoàn vào ví của khách (WalletTransaction)
    db.WalletTransactions.Add(new WalletTransaction
    {
        UserId = order.BuyerId,
        OrderId = order.Id,
        Amount = refundAmount,
        Currency = order.Currency,
        Type = "refund",
        Description = $"Hoàn tiền đơn hàng #{order.Id.ToString()[..8]}: {request.Reason}",
        CreatedAt = DateTime.UtcNow
    });

    // 5. Cập nhật hồ sơ khiếu nại (nếu có)
    if (request.ComplaintId.HasValue)
    {
        var complaint = await db.Complaints.FindAsync(request.ComplaintId.Value);
        if (complaint != null)
        {
            complaint.ResolutionNote = $"Phê duyệt hoàn {refundAmount:N0} {order.Currency} ({rate:P0}): {request.Reason}";
            complaint.Status = ComplaintStatus.Resolved;
            complaint.ResolvedAt = DateTime.UtcNow;
            db.ComplaintStatusHistories.Add(new ComplaintStatusHistory
            {
                ComplaintId = complaint.Id,
                FromStatus = ComplaintStatus.InProgress,
                ToStatus = ComplaintStatus.Resolved,
                ChangedBy = staffId,
                Note = complaint.ResolutionNote,
                ChangedAt = DateTime.UtcNow
            });
        }
    }

    await db.SaveChangesAsync();
    await tx.CommitAsync();

    // 6. Gửi thông báo cho khách hàng
    if (notifications != null)
    {
        await notifications.NotifyVisitorAsync(
            order.BuyerId,
            NotificationTypes.PaymentSucceeded,
            "Yêu cầu hoàn tiền đã được xử lý",
            $"Bạn đã được hoàn {refundAmount:N0} {order.Currency} vào ví cho đơn hàng #{order.Id.ToString()[..8]}.",
            NotificationReferenceTypes.Order,
            order.Id.ToString(),
            "/visitor/wallet");
    }

    return ResponseDto<RefundExecutionResponse>.Success(new RefundExecutionResponse(
        order.Id,
        true,
        refundAmount,
        order.Currency,
        order.Status,
        $"Đã phê duyệt hoàn {refundAmount:N0} {order.Currency} thành công.",
        DateTime.UtcNow));
}
```

---

## 4. HƯỚNG DẪN MIGRATION DATABASE CHO NHÂN VIÊN BE

Sau khi thêm entity `ComplaintStatusHistory.cs` và cập nhật `ApplicationDbContext.cs`, chạy các lệnh sau tại thư mục `SMGS.Infrastructure`:

```bash
# 1. Tạo migration mới
dotnet ef migrations add AddComplaintStatusHistoryAndRefundSupport --project SMGS.Infrastructure --startup-project SMGS.API

# 2. Cập nhật Database
dotnet ef database update --project SMGS.Infrastructure --startup-project SMGS.API
```

---

## 5. CHECKLIST KIỂM THỬ XÁC NHẬN CHO BE (TEST CASES ALIGNMENT)

| Mã Test | Mô tả kiểm thử | Kỳ vọng |
| :--- | :--- | :--- |
| **TC-059** | System Staff xem danh sách khiếu nại và lọc theo trạng thái | Trả về 200 OK kèm danh sách và phân trang |
| **TC-060** | System Staff duyệt hoàn tiền theo chính sách thời gian | Sinh `WalletTransaction(refund)`, cập nhật `RefundedAmount`, thu hồi vé nếu 100% |
| **TC-061** | System Staff từ chối hoàn tiền kèm lý do | Không cộng tiền ví, cập nhật khiếu nại thành Resolved kèm lý do |
| **TC-063** | Chuyển đổi trạng thái khiếu nại từ `New` $\rightarrow$ `InProgress` $\rightarrow$ `Resolved` | Bảng `ComplaintStatusHistory` sinh đúng 3 dòng log ghi nhận `ChangedBy` và `ChangedAt` |
| **TC-064** | Chuyển đổi trạng thái bất hợp lệ (ví dụ: `Resolved` $\rightarrow$ `New`) | BE chặn đứng và trả về `400 Bad Request` |
| **TC-N03** | Nhân viên bảo tàng M1 gọi API doanh thu/báo cáo của M2 | BE chặn đứng với `403 Forbidden` ("Bạn không được phân công quản lý bảo tàng này") |

---

> **Lưu ý:** File tài liệu này đã được lưu tại `FrontEnd/docs/BE_WF05_REMEDIATION_SPEC_2026_11_26.md`. Phía FE (Huỳnh Minh Tâm) sẽ căn cứ đúng vào hợp đồng API ở Mục 2 & 3 để hoàn thiện giao diện nút bấm và thanh tiến trình lịch sử xử lý.
