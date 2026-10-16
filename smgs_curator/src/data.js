export const curator = {
  name: 'TS. Trần Văn Phong',
  email: 'curator@smgs.vn',
  museum: 'Bảo tàng Lịch sử Quốc gia',
  museumId: 'mus-01',
};

export const seedItems = [
  {
    id: 'CUR-101', type: 'Thuyết minh AI', priority: 'Cao', status: 'pending', artifact: 'Trống đồng Ngọc Lũ',
    submittedBy: 'Nguyễn Mai Anh · Nhân viên bảo tàng', submittedAt: '16/10/2026 · 09:30',
    title: 'Thuyết minh dành cho nhóm khách thiếu nhi',
    summary: 'Kịch bản 3 phút, giọng kể gần gũi cho khách 6–12 tuổi.',
    current: 'Bản hiện hành hướng đến khách đại chúng, thời lượng 04:15. Nội dung chưa có cách xưng hô và ví dụ phù hợp với trẻ em.',
    proposed: 'Chào các bạn nhỏ! Hôm nay chúng mình cùng bước vào cỗ máy thời gian để gặp Trống đồng Ngọc Lũ nhé. Trên mặt trống có ngôi sao 14 cánh, chim Lạc và cảnh người xưa giã gạo. Mỗi hình ảnh kể cho ta nghe về cuộc sống cách đây hơn 2.000 năm.',
    checks: ['Niên đại phù hợp hồ sơ hiện vật', 'Thuật ngữ phù hợp nhóm tuổi', 'Không thêm diễn giải chưa kiểm chứng'],
  },
  {
    id: 'CUR-102', type: 'Quiz AI', priority: 'Trung bình', status: 'pending', artifact: 'Thạp đồng Đào Thịnh',
    submittedBy: 'Lê Tuấn Kiệt · Nhân viên bảo tàng', submittedAt: '16/10/2026 · 08:10',
    title: 'Bộ câu hỏi tương tác về Thạp đồng Đào Thịnh',
    summary: 'Đề xuất 4 câu hỏi sau khi khách tham quan đọc thông tin hiện vật.',
    current: 'Chưa có quiz được xuất bản cho hiện vật này.',
    proposed: 'Câu 1: Thạp đồng Đào Thịnh được phát hiện ở tỉnh nào? Đáp án: Yên Bái.\n\nCâu 2: Hình tượng trên nắp thạp thể hiện ước vọng nào? Đáp án: Sinh sôi, nảy nở.',
    checks: ['Đáp án có nguồn trong hồ sơ', 'Ngôn ngữ không gây hiểu nhầm', 'Độ khó phù hợp khách phổ thông'],
  },
  {
    id: 'CUR-103', type: 'Bản dịch tiếng Anh', priority: 'Cao', status: 'revision', artifact: 'Trống đồng Ngọc Lũ',
    submittedBy: 'Nguyễn Mai Anh · Nhân viên bảo tàng', submittedAt: '15/10/2026 · 16:45',
    title: 'Hiệu đính bản dịch mô tả biểu tượng chim Lạc',
    summary: 'Cần làm rõ sắc thái “bird motif” thay vì khẳng định định danh tuyệt đối.',
    current: 'The drum depicts Lac birds flying around a sun-shaped star.',
    proposed: 'The drum features stylized bird motifs circling a 14-rayed star, commonly interpreted in Vietnamese scholarship as images associated with Lac birds.',
    checks: ['Giữ đúng mức độ chắc chắn của tư liệu', 'Thuật ngữ nhất quán với danh mục song ngữ', 'Không dịch vượt nghĩa nguồn tiếng Việt'],
    feedback: 'Cần trích dẫn nguồn học thuật nội bộ ở trường “Nguồn tham chiếu” trước khi gửi lại.',
  },
  {
    id: 'CUR-104', type: 'Thông tin hiện vật', priority: 'Thấp', status: 'published', artifact: 'Rìu đồng Đông Sơn',
    submittedBy: 'Nguyễn Mai Anh · Nhân viên bảo tàng', submittedAt: '14/10/2026 · 10:20',
    title: 'Bổ sung kỹ thuật chế tác và tình trạng bảo quản',
    summary: 'Bổ sung mô tả đúc khuôn và tình trạng hiện vật theo biên bản kiểm kê.',
    current: 'Hiện vật bằng đồng, niên đại Văn hóa Đông Sơn.',
    proposed: 'Hiện vật được đúc đồng bằng khuôn, thuộc Văn hóa Đông Sơn. Bề mặt có lớp patina ổn định; được bảo quản trong điều kiện kiểm soát độ ẩm.',
    checks: ['Khớp biên bản kiểm kê', 'Thuật ngữ bảo quản đúng chuẩn', 'Đã kiểm tra ảnh minh họa'],
    publishedAt: '14/10/2026 · 14:05',
  },
];
