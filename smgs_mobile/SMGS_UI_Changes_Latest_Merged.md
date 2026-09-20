# SMGS – Updated UI Change Specification (Merged)

## 1. Purpose

Tài liệu này là bản **đã đối chiếu và hợp nhất** giữa UI change specification trước đó của SMGS và bản mô tả chi tiết 5 Main Flows mới nhất.

Mục đích của file:

- Làm baseline để sửa UI/Figma.
- Đồng bộ UI với 5 Main Flows hiện tại.
- Ghi rõ business rules mới ảnh hưởng trực tiếp tới UI.
- Giữ lại các thay đổi trước đó vẫn còn hiệu lực như:
  - Google Maps để chỉ đường đến bảo tàng.
  - One Account = One Active Device Session.
  - 3D Artifact Viewer.
  - 3D Museum Map.
  - Museum Staff role.
  - Supporting functions không được tính là Main Flow.
  - Theme cổ điển, tối giản, tối đa 4 màu chính.

---

# 2. Official Main Flows

Hệ thống hiện có **5 Main Flows chính thức**:

| Code | Main Flow | Primary Actor |
|---|---|---|
| MF-01 | Artifact Discovery & AI Guide | Visitor |
| MF-02 | Quiz & Gamification | Visitor |
| MF-03 | Personalized Tour & Navigation | Visitor |
| MF-04 | Ticket, Digital Guide & Payment | Visitor |
| MF-05 | Content Creation, Review & Publishing | Staff / Museum Staff |

Các chức năng sau vẫn bắt buộc nhưng chỉ là **Supporting Functions**:

- Search & Browse
- Visit History & Feedback
- Museum & Artifact Content Management
- User, Role & Access Management

---

# 3. MF-01 – Artifact Discovery & AI Guide

## Actors

- **Primary Actor:** Visitor
- **Supporting Actor:** AI System

## Goal

Giúp Visitor xác định hiện vật, tiếp cận nội dung đã được kiểm duyệt, nghe/xem thuyết minh phù hợp và trao đổi với AI về hiện vật.

## Main Flow

1. Visitor đăng nhập vào SMGS.
2. Visitor chọn bảo tàng muốn tham quan.
3. Visitor tìm hoặc xác định hiện vật bằng:
   - QR code.
   - Image recognition.
   - Museum map.
   - Artifact list / search.
4. Hệ thống xác định artifact.
5. Hệ thống hiển thị approved artifact content.
6. Visitor chọn:
   - Language.
   - Narration type.
   - Narration length.
   - Detail level.
7. Hệ thống cung cấp narration dạng text/audio trong phạm vi hỗ trợ.
8. Nếu artifact có 3D model, Visitor có thể chọn **View in 3D**.
9. Visitor mở AI Guide.
10. Visitor đặt câu hỏi liên quan đến artifact.
11. AI trả lời từ knowledge sources đã được approve/publish.
12. Visitor có thể tiếp tục:
   - hỏi artifact hiện tại;
   - chuyển sang artifact khác trong cùng conversation.
13. Hệ thống lưu conversation và messages để Visitor xem lại.

## New / Important Business Rules

### BR-MF01-01 – Visited Artifact

Chỉ **QR scan thành công** mới tự động ghi nhận artifact là đã tham quan.

```text
Successful QR Scan
→ Mark Artifact as Visited
```

Các hành động sau **không tự động** được tính là visited:

```text
Image Recognition
Open Artifact Detail
Search Artifact
Open from List
```

### BR-MF01-02 – AI Answer Approval

AI không cần staff duyệt từng câu trả lời trước khi gửi Visitor.

Tuy nhiên:

```text
AI Answer
must use
Approved / Published Knowledge Sources
```

### BR-MF01-03 – Multi-Artifact Conversation

Một conversation có thể chứa context của nhiều artifact.

Ví dụ:

```text
Conversation #001
├── Artifact A
├── Artifact B
└── Artifact C
```

Conversation không bị khóa cứng vào một artifact duy nhất.

### BR-MF01-04 – Conversation History

Conversation và messages phải được lưu để Visitor có thể xem lại.

---

# 4. MF-01 UI Changes

## Artifact Detail

Giữ:

- Artifact image
- Artifact name
- Description
- Historical information
- Gallery / exhibition
- Listen to Narration
- Ask AI Guide
- Take Quiz

Thêm:

```text
[ View in 3D ]
```

nếu artifact có 3D model.

## Narration Settings

Nên có một màn hình / bottom sheet đơn giản:

```text
Narration Settings

Language
[ Vietnamese ▼ ]

Length
( ) Short
( ) Standard
( ) Detailed

Format
( ) Text
( ) Audio

[ Start Narration ]
```

## AI Guide

Cần hỗ trợ:

- Conversation history.
- Suggested questions.
- Current artifact context.
- Chuyển artifact nhưng giữ conversation.
- Xem lại conversation cũ.

### Suggested UI

```text
AI Museum Guide

Current Artifact:
Artifact B

Conversation:
Visitor: ...
AI: ...

[ Ask a question... ]

[ Change Artifact Context ]
```

## New Screen – Conversation History

```text
AI Conversations

20/09/2026
Museum A
3 Artifacts

[ Open Conversation ]

18/09/2026
Museum B
1 Artifact

[ Open Conversation ]
```

---

# 5. MF-02 – Quiz & Gamification

## Primary Actor

Visitor

## Goal

Tăng tương tác và học tập thông qua quiz, points, badges và achievements.

## Main Flow

1. Visitor mở artifact có quiz.
2. Visitor bắt đầu quiz attempt.
3. Hệ thống chọn khoảng **2–3 approved questions** từ question bank.
4. Hệ thống hiển thị từng câu.
5. Visitor trả lời.
6. Hệ thống kiểm tra.
7. Hệ thống hiển thị instant feedback.
8. Nếu câu trả lời đúng và thỏa điều kiện, hệ thống cộng points.
9. Hệ thống kiểm tra badge condition.
10. Nếu đủ điều kiện và chưa có badge đó, hệ thống award badge.
11. Hệ thống tính final quiz result.
12. Hệ thống lưu:
    - attempt;
    - total result;
    - individual answers.
13. Visitor có thể reset để tạo một attempt mới.

## New / Important Business Rules

### BR-MF02-01 – Quiz and Question Relationship

Quiz thuộc về một artifact.

Question được tạo trước và kiểm duyệt.

Một Question có thể được tái sử dụng trong nhiều Quiz.

### BR-MF02-02 – Random / Selected Questions

Mỗi attempt sử dụng khoảng **2–3 approved questions** từ question bank theo rule của hệ thống.

### BR-MF02-03 – Reset

Reset không xóa attempt cũ.

```text
Reset Quiz
→ Create New Attempt
→ Keep Previous Attempt
```

### BR-MF02-04 – Point Sources

Nguồn point đã được xác nhận hiện tại:

1. Successful artifact QR scan.
2. Correct quiz answers.

### BR-MF02-05 – Badge Uniqueness

Một badge cụ thể chỉ được cấp **một lần cho mỗi account**.

---

# 6. MF-02 UI Changes

## Quiz Screen

- One question per screen.
- Progress indicator.
- Answer options.
- Submit.
- Instant feedback.

## Quiz Result

Thêm:

- Attempt number / time.
- Correct answers.
- Total score.
- Points earned.
- New badges.
- **Try Another Quiz / Reset**.

Ví dụ:

```text
Quiz Completed

Score: 2 / 3
Points Earned: +20

New Badge:
Museum Explorer

[ Try Again ]

[ Back to Artifact ]
```

## Quiz History

Không overwrite attempt cũ.

```text
Quiz History

Artifact A

Attempt #3
2/3
20/09/2026

Attempt #2
3/3
18/09/2026
```

---

# 7. MF-03 – Personalized Tour & Navigation

## Actors

- **Primary Actor:** Visitor
- **Supporting Actor:** AI System

Google Maps vẫn được dùng như một supporting integration để dẫn người dùng **đến bảo tàng**, nhưng không thay thế museum map bên trong.

## Goal

Cho phép Visitor:

- Chọn tour mẫu.
- Hoặc yêu cầu AI tạo personalized tour.
- Chỉnh sửa tour.
- Bắt đầu Visit Session.
- Theo dõi current location.
- Xem artifact icons.
- Theo dõi thứ tự artifact cần tham quan.

## Main Flow

1. Visitor đăng nhập và chọn museum.
2. Visitor chọn:
   - Existing / Staff-created Tour; hoặc
   - AI Personalized Tour.
3. Nếu chọn AI Personalized Tour, Visitor nhập:
   - Interests.
   - Available time.
4. AI đề xuất ordered artifact list.
5. Hệ thống lưu tour.
6. Visitor review/edit tour.
7. Visitor chọn **Start Tour**.
8. Hệ thống tạo **Visit Session** mới.
9. Hệ thống hiển thị map theo floor/area.
10. Map hiển thị:
    - Current Visitor Location.
    - Artifact Icons.
    - Tour Order.
11. Visitor tự di chuyển giữa các artifact.
12. Khi Visitor scan QR thành công:
    - artifact được ghi nhận visited;
    - tour stop được cập nhật;
    - Visit Session progress được cập nhật.
13. Khi kết thúc, hệ thống lưu Visit History.

---

# 8. MF-03 Important Business Rules

## BR-MF03-01 – Two Tour Sources

Tour có thể đến từ:

```text
Staff-created Tour
or
AI-generated Personalized Tour
```

Cả hai đều là ordered artifact lists.

## BR-MF03-02 – AI Tour Persistence

AI-generated tour phải được lưu.

Visitor có thể chỉnh sửa tour trước / trong phạm vi hệ thống cho phép.

## BR-MF03-03 – Interests are Per Request

Interests không phải profile preference cố định.

```text
Interest Input
belongs to
Current Tour Recommendation Request
```

## BR-MF03-04 – Visit Session

Khi Visitor bắt đầu tour, hệ thống tạo một Visit Session riêng.

Visit Session theo dõi:

- Museum.
- Start time.
- Tour used.
- Visited artifacts.
- Progress.
- End time.

## BR-MF03-05 – No Automatic Turn-by-Turn Routing

**Quan trọng:** hiện tại hệ thống **không cam kết**:

- tự động tính shortest route;
- turn-by-turn indoor navigation;
- automatic indoor route guidance.

Scope hiện tại chỉ bao gồm:

```text
Determine / Receive Visitor Location
→ Show Location on Map
→ Show Artifact Icons
→ Show Tour Order
→ Visitor follows the map manually
```

Lý do: indoor positioning / routing technology cần xác nhận thêm.

## BR-MF03-06 – 3D Museum Map

Nếu 3D map vẫn được dùng, nó là **visual indoor museum map**.

Không nên thiết kế UI giống GPS turn-by-turn.

---

# 9. MF-03 UI Changes

## Tour Entry Screen

```text
Choose Your Tour

[ Museum Recommended Tours ]

[ Create Personalized Tour ]
```

## AI Tour Setup

```text
Available Time
[ 60 minutes ▼ ]

Interests
[ History ]
[ Art ]
[ Culture ]

[ Generate Tour ]
```

## Tour Review / Edit

```text
Your Tour

1. Artifact A
2. Artifact B
3. Artifact C
4. Artifact D

[ Reorder ]
[ Remove Artifact ]
[ Add Artifact ]

[ Start Tour ]
```

## Visit Session Map

Map phải tập trung vào:

- current location;
- floor;
- artifact icons;
- numbered tour order;
- completed / uncompleted stops.

Ví dụ:

```text
Museum A – Floor 1

You are here: ●

1  Artifact A   ✓
2  Artifact B   ← Next
3  Artifact C
4  Artifact D

[ Open Artifact B ]

[ End Visit ]
```

Không nên có UI kiểu:

```text
Turn left in 10m
Go straight for 25m
```

trừ khi requirement indoor routing sau này được xác nhận.

---

# 10. Google Maps – External Navigation

Google Maps vẫn dùng để chỉ đường **đến museum**.

```text
Museum Detail
→ Get Directions
→ Google Maps
→ Museum
```

## Museum Detail

Thêm:

- Address.
- Location.
- Get Directions.

```text
Museum A

123 Example Street

[ Get Directions ]
```

## Separation Rule

```text
Google Maps
= External navigation to museum

Museum Map / 3D Museum Map
= Indoor museum visualization and tour tracking
```

---

# 11. MF-04 – Ticket, Digital Guide & Payment

## Actors

- **Primary Actor:** Visitor
- **Supporting Actor:** Payment Gateway

## Goal

Cho phép Visitor mua các sản phẩm/dịch vụ của museum trên SMGS.

## Supported Products

### Product 1 – Museum Entrance Ticket

Vé vào cửa bảo tàng.

### Product 2 – Digital Guide

Quyền sử dụng hướng dẫn số trên SMGS.

Có thể bao gồm các chức năng được museum cấu hình như:

- AI Guide.
- Narration.
- Digital content.
- Other guide functions.

### Product 3 – Ticket + Digital Guide Combo

Bao gồm:

```text
Museum Entrance Ticket
+
Digital Guide Access
```

---

# 12. MF-04 Main Flow

1. Visitor login.
2. Visitor selects Museum.
3. Visitor selects product:
   - Museum Entrance Ticket.
   - Digital Guide.
   - Ticket + Digital Guide Combo.
4. System displays product information, price and benefits.
5. Visitor confirms purchase.
6. System creates **Purchase Order**.
7. System sends payment request to Payment Gateway.
8. Visitor completes payment.
9. Gateway returns transaction result.
10. Backend verifies result.
11. If successful:
    - Ticket → issue museum ticket / admission entitlement.
    - Digital Guide → activate guide access.
    - Combo → issue both.
12. System saves transaction history.
13. System creates invoice information according to configured process.
14. Visitor can view:
    - ticket;
    - Digital Guide entitlement;
    - purchase history;
    - transaction history.

---

# 13. MF-04 Important Business Rules

## BR-MF04-01 – Existing Museum Ticket

Visitor đã mua vé trực tiếp tại museum **không bắt buộc phải mua lại ticket trên SMGS**.

Visitor vẫn có thể mua riêng:

```text
Digital Guide
```

## Important Change From Previous UI Draft

Bản UI trước từng giả định có flow:

```text
Link Existing Ticket
→ Verify External Ticket
```

Theo Main Flow mới nhất, flow này **không còn là requirement đã xác nhận**.

Vì vậy:

- Không lấy **Link Existing Ticket** làm flow chính.
- Không cần bắt buộc có screen scan external ticket.
- Visitor đã có museum ticket bên ngoài chỉ cần mua riêng Digital Guide nếu muốn.

Nếu sau này museum yêu cầu ticket linking/verification, sẽ bổ sung như feature riêng.

## BR-MF04-02 – Purchase Order

Mỗi purchase bắt đầu bằng một Purchase Order.

## BR-MF04-03 – Multiple Payment Attempts

Một Order có thể có nhiều Payment Attempts.

```text
Order #1001
├── Payment Attempt #1 – FAILED
├── Payment Attempt #2 – FAILED
└── Payment Attempt #3 – SUCCESS
```

Failed attempts vẫn phải được lưu.

## BR-MF04-04 – Payment Failure

```text
Payment Failed
→ Save Failed Attempt
→ Inform Visitor
→ Retry Payment
```

Không tạo ticket/access entitlement khi payment chưa được verified successful.

---

# 14. MF-04 UI Changes

## Museum Purchase Entry

Museum Detail nên có:

```text
Tickets & Digital Guide
```

## Product Selection Screen

```text
Museum A

Choose a Product

[ Museum Entrance Ticket ]
50,000 VND

[ Digital Guide ]
20,000 VND

[ Ticket + Digital Guide Combo ]
65,000 VND
```

## Ticket Purchase

```text
Museum Entrance Ticket

Visit Date
[ 20/09/2026 ]

Adult
[-] 1 [+]

Student
[-] 0 [+]

[ Continue ]
```

## Digital Guide Purchase

```text
Digital Guide

Access includes:
- AI Guide
- Audio Narration
- Digital Content

Visit Date
[ 20/09/2026 ]

Price
20,000 VND

[ Continue ]
```

## Combo Purchase

```text
Ticket + Digital Guide Combo

Includes:
✓ Museum Entrance Ticket
✓ Digital Guide

Visit Date
[ 20/09/2026 ]

[ Continue ]
```

## Checkout

```text
Order Summary

Museum A
Product: Ticket + Digital Guide Combo
Date: 20/09/2026

Total: 65,000 VND

Payment Method
( ) VNPay
( ) MoMo

[ Confirm Payment ]
```

## Payment Failed

```text
Payment Unsuccessful

Your payment could not be completed.

[ Retry Payment ]

[ View Order ]
```

## Payment Success

```text
Payment Successful

Your purchase has been activated.

[ View Ticket ]

[ Open Digital Guide ]
```

Button hiển thị tùy product.

---

# 15. Purchase / Payment History UI

Do có multiple payment attempts, nên Order Detail có thể hiển thị:

```text
Order #SMGS-1001

Ticket + Digital Guide Combo
65,000 VND

Status: PAID

Payment Attempts

1. VNPay – Failed
   14:02

2. VNPay – Successful
   14:05
```

Visitor không cần xem technical gateway payload.

---

# 16. MF-05 – Content Creation, Review & Publishing

## Actors

- **Primary Actor:** Staff / Museum Staff
- **Supporting Actor:** AI System
- **Reviewer:** Authorized Reviewer / Curator / Staff with review permission

## Goal

Quản lý toàn bộ lifecycle của museum content:

- Artifact information.
- Media.
- Narration.
- Translation.
- Knowledge source.
- Quiz content.
- AI-generated drafts.
- Published versions.

---

# 17. MF-05 Main Flow

1. Staff accesses content within assigned scope.
2. Staff creates or updates content.
3. Staff optionally requests AI draft.
4. AI generates draft.
5. Staff edits draft if needed.
6. System creates a **new content version**.
7. Creator submits version for review.
8. Reviewer reviews content and related sources.
9. Reviewer selects:
   - Approve; or
   - Reject / Request Changes.
10. If rejected:
    - content returns to editing.
11. If approved:
    - authorized user publishes content.
12. System marks new version as Published.
13. System records:
    - Creator.
    - Reviewer.
    - Version.
    - Review Result.
    - Published At.
14. Visitor receives the new published version.

---

# 18. MF-05 Important Business Rules

## BR-MF05-01 – Existing Published Version Remains Active

Nếu version mới đang:

- Draft.
- Under Review.
- Rejected.
- Approved but not Published.

Visitor vẫn xem **published version cũ**.

```text
Version 1 – Published → Visitor sees this

Version 2 – Under Review
→ Visitor does NOT see Version 2 yet
```

Sau khi Version 2 publish:

```text
Version 2 – Published
→ Becomes current visitor version
```

## BR-MF05-02 – Version History

Hệ thống phải giữ version history.

## BR-MF05-03 – Review History

Ghi nhận:

- Creator.
- Reviewer.
- Result.
- Timestamp.
- Publish timestamp.

## BR-MF05-04 – Museum Staff Permissions

Museum Staff được xác nhận có quyền:

- Add Artifact.

Các quyền sau vẫn cần xác nhận cụ thể:

- Edit.
- Delete.
- Approve.
- Publish.

Do đó UI phân quyền nên được thiết kế để có thể bật/tắt action theo permission.

---

# 19. MF-05 UI Changes

## Content Statuses

Nên hỗ trợ:

- Draft
- Under Review
- Changes Requested
- Approved
- Rejected
- Published
- Archived

## Content Editor

```text
Artifact A

Current Published Version
v1.3

New Draft
v1.4

[ Edit ]

[ Submit for Review ]
```

## Review Screen

```text
Artifact A
Version 1.4

Creator:
Museum Staff A

Source Information
[...]

Draft Content
[...]

[ Approve ]

[ Request Changes ]

[ Reject ]
```

## Publish Screen

```text
Version 1.4
Status: Approved

Current Published:
Version 1.3

Publishing v1.4 will make it
the current visitor version.

[ Publish ]
```

## Version History

```text
Version History

v1.4 – Published
Reviewer: Curator A
20/09/2026

v1.3 – Archived / Previous Published
18/09/2026

v1.2 – Rejected
17/09/2026
```

---

# 20. One Account = One Active Device Session

Rule trước đó vẫn giữ nguyên.

Mỗi account chỉ có một active device session.

## New Device Login

```text
New Login Detected

Your account is currently active
on another device.

Continuing will sign out
the other device.

[ Continue Login ]

[ Cancel ]
```

## Previous Device

```text
Session Ended

Your account was signed in
on another device.

[ Sign In ]
```

---

# 21. 3D Artifact Viewer

Feature trước đó vẫn giữ.

Artifact Detail hiển thị:

```text
[ View in 3D ]
```

chỉ khi 3D model tồn tại.

## UI

```text
Artifact Name

┌───────────────────────┐
│                       │
│       3D MODEL        │
│                       │
└───────────────────────┘

Drag to rotate
Pinch to zoom

[ Reset View ]

[ Back ]
```

Hiện tại:

```text
3D Viewer ≠ AR
```

---

# 22. Updated Museum Detail

Nên tổ chức theo section để tránh quá nhiều button.

## Visit

```text
[ Get Directions ]
[ Tickets & Digital Guide ]
```

## Explore

```text
[ Explore Artifacts ]
[ Search Artifacts ]
[ View Exhibitions ]
```

## Tour

```text
[ Museum Tours ]
[ Create Personalized Tour ]
[ Museum Map ]
```

---

# 23. Updated Profile

Nên có:

- My Tickets
- Digital Guide Access
- Purchase History
- Visit History
- Quiz History
- Badges
- AI Conversation History
- Settings
- Logout

---

# 24. Updated Screen List

| ID | Screen |
|---|---|
| UI-01 | Splash |
| UI-02 | Login / Register |
| UI-03 | Home |
| UI-04 | Museum List |
| UI-05 | Museum Detail |
| UI-06 | Artifact Discovery |
| UI-07 | QR Scan |
| UI-08 | Image Recognition |
| UI-09 | Artifact Detail |
| UI-10 | Narration Settings |
| UI-11 | Artifact 3D Viewer |
| UI-12 | AI Museum Guide |
| UI-13 | AI Conversation History |
| UI-14 | Quiz |
| UI-15 | Quiz Result |
| UI-16 | Quiz History |
| UI-17 | Tour Selection |
| UI-18 | Personalized Tour Setup |
| UI-19 | Tour Review / Edit |
| UI-20 | Visit Session Map / 3D Museum Map |
| UI-21 | Search & Browse |
| UI-22 | Visit History |
| UI-23 | Feedback |
| UI-24 | Product Selection – Ticket / Digital Guide / Combo |
| UI-25 | Ticket Purchase |
| UI-26 | Digital Guide Purchase |
| UI-27 | Combo Purchase |
| UI-28 | Checkout |
| UI-29 | Payment Result |
| UI-30 | Order / Purchase History |
| UI-31 | Ticket Detail |
| UI-32 | Digital Guide Access |
| UI-33 | Profile |
| UI-34 | New Device Login Confirmation |
| UI-35 | Session Revoked |
| UI-36 | Google Maps / Get Directions |
| UI-37 | Content Editor |
| UI-38 | Content Review |
| UI-39 | Publish Confirmation |
| UI-40 | Content Version History |

ID có thể đổi lại theo Figma hiện tại của team.

---

# 25. Updated Main Flow to UI Mapping

| Main Flow | Main UI Screens |
|---|---|
| MF-01 Artifact Discovery & AI Guide | Artifact Discovery, QR Scan, Image Recognition, Artifact Detail, Narration Settings, 3D Viewer, AI Guide, Conversation History |
| MF-02 Quiz & Gamification | Quiz, Quiz Result, Quiz History |
| MF-03 Personalized Tour & Navigation | Tour Selection, Personalized Tour Setup, Tour Review/Edit, Visit Session Map / 3D Museum Map |
| MF-04 Ticket, Digital Guide & Payment | Product Selection, Ticket Purchase, Digital Guide Purchase, Combo Purchase, Checkout, Payment Result, Purchase History, Ticket Detail, Digital Guide Access |
| MF-05 Content Creation, Review & Publishing | Content Editor, Review Screen, Publish Confirmation, Version History |

---

# 26. Updated Prototype Flows for Figma

## Prototype A – Artifact / Narration / 3D / AI

```text
Home
→ Museum
→ Artifact Discovery
→ QR / Image / Search
→ Artifact Detail
→ Narration Settings
→ 3D Viewer
→ AI Guide
→ Conversation Saved
```

## Prototype B – Quiz

```text
Artifact Detail
→ Start Quiz
→ 2–3 Questions
→ Instant Feedback
→ Result
→ Points / Badge
→ Quiz History
```

## Prototype C – Personalized Tour

```text
Museum
→ Select Existing Tour / Personalized Tour
→ Enter Interests & Time
→ AI Generates Tour
→ Review / Edit
→ Start Visit Session
→ Museum Map
→ Scan QR at Artifact
→ Update Progress
→ Complete Visit
```

## Prototype D – Ticket Purchase

```text
Museum
→ Tickets & Digital Guide
→ Museum Entrance Ticket
→ Select Date / Quantity
→ Checkout
→ Payment
→ Ticket Issued
```

## Prototype E – Digital Guide Purchase

```text
Museum
→ Tickets & Digital Guide
→ Digital Guide
→ Checkout
→ Payment
→ Guide Access Activated
```

Dùng được cho Visitor đã mua entrance ticket trực tiếp tại museum.

## Prototype F – Combo Purchase

```text
Museum
→ Tickets & Digital Guide
→ Combo
→ Checkout
→ Payment
→ Ticket Issued
→ Digital Guide Activated
```

## Prototype G – Content Review

```text
Create / Edit Content
→ Optional AI Draft
→ New Version
→ Submit Review
→ Reviewer
→ Approve / Request Changes
→ Publish
→ New Version Visible to Visitor
```

---

# 27. Supporting Functions

Vẫn bắt buộc nhưng không tính là Main Flow:

## SF-01 – Search & Browse

- Search Museum.
- Search Artifact.
- Browse Exhibitions.
- Browse Galleries.
- Browse Themes.

## SF-02 – Visit History & Feedback

- View visited artifacts.
- View Visit Sessions.
- View quiz attempts.
- View tour history.
- Submit ratings / feedback.

## SF-03 – Museum & Artifact Management

Museum Staff:

- Add Artifact.
- Upload image.
- Upload media.
- Upload 3D model.
- Set location.
- Manage exhibitions.
- Manage artifact content.

Detailed edit/delete/publish permissions depend on role configuration.

## SF-04 – User, Role & Access Management

Administrator:

- Manage users.
- Manage roles.
- Museum assignments.
- Permissions.
- Sessions.
- Audit logs.

---

# 28. Visual Design Rules – Unchanged

UI vẫn phải:

- Classic museum-inspired.
- Minimal.
- Dễ dùng cho middle-aged / older visitors.
- Không quá hiện đại.
- Không flashy.
- Không neon.
- Không dùng quá nhiều visual effects.
- Text lớn và rõ.
- Button lớn.
- Important icon phải có label.
- Tối đa **4 primary colors**.

## Current Color Palette

| Color | Hex | Usage |
|---|---|---|
| Antique Ivory | `#F4EBDD` | Main background |
| Deep Burgundy | `#6B2E2E` | Primary actions |
| Dark Brown | `#3B302A` | Text / icons |
| Muted Gold | `#B38B59` | Heritage accent / badges |

---

# 29. Key Differences Applied From the New Main Flow Document

Các điểm mới đã được merge vào UI baseline:

1. **QR scan mới là hành động xác nhận artifact visited.**
2. **Narration có language + length/detail selection.**
3. **AI conversation có thể đi qua nhiều artifact.**
4. **AI conversations/messages được lưu.**
5. **Quiz attempt lấy khoảng 2–3 approved questions.**
6. **Question có thể reusable giữa nhiều quiz.**
7. **Reset quiz tạo attempt mới, không xóa attempt cũ.**
8. **Point hiện có từ QR scan + correct quiz answer.**
9. **Badge cụ thể chỉ được award một lần/account.**
10. **Tour có 2 nguồn: staff-created hoặc AI-generated.**
11. **AI tour được save và edit.**
12. **Interest là input theo từng request, không phải profile preference cố định.**
13. **Start tour tạo Visit Session.**
14. **Museum map chỉ cần show current location + artifact icons + tour order.**
15. **Không cam kết turn-by-turn indoor routing ở scope hiện tại.**
16. **MF-04 đổi sang Ticket / Digital Guide / Combo.**
17. **Visitor đã mua ticket ngoài museum vẫn có thể mua riêng Digital Guide.**
18. **Flow Link Existing Ticket không còn là requirement xác nhận.**
19. **Order có thể có nhiều Payment Attempts.**
20. **Failed payment attempts phải được lưu.**
21. **MF-05 mở rộng thành full Content Creation → Review → Publishing lifecycle.**
22. **Version mới chờ review không thay thế published version hiện tại.**
23. **Hệ thống lưu content version history và review history.**
24. **Museum Staff chắc chắn được Add Artifact; edit/delete/approve/publish cần xác nhận permission cụ thể.**

---

# 30. UI Update Checklist

- [ ] Artifact visited chỉ được ghi nhận sau successful QR scan.
- [ ] Narration có language + length/detail selection.
- [ ] AI Guide hỗ trợ multi-artifact conversation.
- [ ] Có Conversation History.
- [ ] Có 3D Artifact Viewer.
- [ ] Quiz dùng attempt model.
- [ ] Reset quiz tạo attempt mới.
- [ ] Quiz History không overwrite attempt cũ.
- [ ] Point UI hỗ trợ QR-scan points và quiz points.
- [ ] Badge không award duplicate.
- [ ] Tour Selection có Existing Tour và Personalized Tour.
- [ ] AI Tour có Review/Edit.
- [ ] Start Tour tạo Visit Session.
- [ ] Museum Map hiển thị current location.
- [ ] Museum Map hiển thị artifact icons.
- [ ] Museum Map hiển thị tour order.
- [ ] Không design turn-by-turn indoor directions nếu requirement chưa xác nhận.
- [ ] Google Maps chỉ dùng để đi đến museum.
- [ ] Purchase UI có Ticket.
- [ ] Purchase UI có Digital Guide.
- [ ] Purchase UI có Combo.
- [ ] Không bắt buộc Link Existing Ticket screen.
- [ ] Order có Payment Attempt states.
- [ ] Failed payment có Retry.
- [ ] Profile có Ticket / Digital Guide / Purchase History.
- [ ] Content UI có Version.
- [ ] Published old version vẫn active khi new version under review.
- [ ] Có Review / Approve / Request Changes / Reject / Publish states.
- [ ] Museum Staff permission-based actions.
- [ ] One Account = One Active Device Session vẫn được giữ.
- [ ] UI vẫn dùng tối đa 4 màu chính.
- [ ] UI vẫn tối giản, cổ điển và dễ dùng cho người lớn tuổi.

---

# 31. Final Updated System View

```text
SMGS
│
├── MF-01 Artifact Discovery & AI Guide
│   ├── QR Scan → Visited
│   ├── Image Recognition
│   ├── Search / Map
│   ├── Narration Settings
│   ├── 3D Artifact Viewer
│   ├── AI Multi-Artifact Conversation
│   └── Conversation History
│
├── MF-02 Quiz & Gamification
│   ├── Question Bank
│   ├── 2–3 Questions / Attempt
│   ├── Instant Feedback
│   ├── Points
│   ├── Badges
│   └── Attempt History
│
├── MF-03 Personalized Tour & Navigation
│   ├── Staff-created Tour
│   ├── AI Personalized Tour
│   ├── Tour Edit
│   ├── Visit Session
│   ├── Current Location
│   ├── Artifact Icons
│   └── Tour Order
│
├── MF-04 Ticket, Digital Guide & Payment
│   ├── Museum Entrance Ticket
│   ├── Digital Guide
│   ├── Combo
│   ├── Purchase Order
│   ├── Payment Attempts
│   ├── Transaction History
│   └── Invoice
│
├── MF-05 Content Creation, Review & Publishing
│   ├── Create / Edit
│   ├── AI Draft
│   ├── Version
│   ├── Review
│   ├── Approve / Reject
│   ├── Publish
│   └── Version History
│
├── Supporting Functions
│   ├── Search & Browse
│   ├── Visit History & Feedback
│   ├── Museum & Artifact Management
│   └── User / Role / Access Management
│
└── Cross-System Rules
    ├── One Account = One Active Device Session
    ├── Google Maps = Navigation to Museum
    └── Museum Map / 3D Map = Indoor Visualization
```
