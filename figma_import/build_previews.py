"""Generate editable SVG reference screens for the SMGS Figma file."""

from html import escape
from pathlib import Path

ROOT = Path(__file__).parent
PAPER = '#F4EBDD'
CARD = '#F8F1E7'
BORDER = '#DACBB5'
BURGUNDY = '#6B2E2E'
BROWN = '#3B302A'
GOLD = '#B38B59'
MUTED = '#5F4D44'


class SVG:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.items = []

    def rect(self, x, y, w, h, fill, radius=0, stroke=None):
        border = f' stroke="{stroke}" stroke-width="1"' if stroke else ''
        self.items.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}"{border}/>')

    def text(self, x, y, value, size=16, color=BROWN, serif=False, weight=400, spacing=0):
        family = 'Noto Serif' if serif else 'Noto Sans'
        self.items.append(f'<text x="{x}" y="{y}" fill="{color}" font-family="{family}" font-size="{size}" font-weight="{weight}" letter-spacing="{spacing}">{escape(str(value))}</text>')

    def circle(self, x, y, r, fill, stroke=None):
        border = f' stroke="{stroke}" stroke-width="1"' if stroke else ''
        self.items.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}"{border}/>')

    def line(self, x1, y1, x2, y2, color=BORDER):
        self.items.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}"/>')

    def save(self, name):
        body = '\n'.join(self.items)
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.width}" height="{self.height}" viewBox="0 0 {self.width} {self.height}">\n{body}\n</svg>\n'
        (ROOT / name).write_text(svg, encoding='utf-8')


def web_screen(filename, role, subtitle, hero, description, menu, metrics, rows, aside):
    s = SVG(1440, 900)
    s.rect(0, 0, 1440, 900, PAPER)
    s.rect(0, 0, 270, 900, BROWN)
    s.rect(20, 18, 40, 40, BURGUNDY, 10, GOLD)
    s.text(31, 46, '▣', 22, PAPER)
    s.text(72, 37, 'SMGS · DI SẢN', 18, PAPER, True, 700)
    s.text(72, 55, 'KHÔNG GIAN NGHIỆP VỤ', 10, '#D9BFA0', weight=700, spacing=1)
    s.line(0, 72, 270, 72, '#705B50')
    s.text(24, 119, subtitle.upper(), 10, '#D9BFA0', weight=700, spacing=1)
    for i, item in enumerate(menu):
        y = 137 + i * 50
        if i == 0:
            s.rect(14, y, 242, 38, BURGUNDY, 8)
        s.circle(35, y + 19, 7, GOLD if i == 0 else '#D9BFA0')
        s.text(54, y + 24, item, 13, PAPER, weight=600 if i == 0 else 400)
    s.line(0, 850, 270, 850, '#705B50')
    s.text(25, 878, 'Bản giao diện thử nghiệm', 11, '#D9BFA0')

    s.rect(270, 0, 1170, 68, CARD)
    s.line(270, 68, 1440, 68)
    s.text(302, 39, role, 13, BURGUNDY, weight=700)
    s.rect(1183, 16, 225, 38, PAPER, 19, BORDER)
    s.circle(1204, 35, 13, BURGUNDY)
    s.text(1228, 39, role, 12, BROWN, weight=600)

    hero_color = BROWN if role == 'Quản trị viên' else BURGUNDY
    s.rect(304, 96, 1100, 220, hero_color, 12)
    s.text(338, 133, subtitle.upper(), 11, '#D9BFA0', weight=700, spacing=1)
    s.text(338, 181, hero, 30, PAPER, True, 700)
    s.text(338, 211, description, 14, '#EEE0CC')
    s.rect(338, 241, 210, 42, PAPER, 7)
    s.text(359, 268, menu[1] if len(menu) > 1 else 'Xem chi tiết', 13, BROWN, weight=700)
    s.circle(1354, 109, 99, 'none', '#987447')

    for i, (value, label, note) in enumerate(metrics):
        x = 304 + i * 280
        s.rect(x, 342, 260, 121, CARD, 10, BORDER)
        s.rect(x + 18, 367, 43, 43, '#EEDBD4', 9)
        s.text(x + 31, 395, '◆', 17, BURGUNDY)
        s.text(x + 76, 385, value, 22, BROWN, weight=700)
        s.text(x + 76, 407, label, 12, MUTED)
        s.text(x + 76, 427, note, 10, '#826E63')

    s.rect(304, 489, 740, 358, CARD, 10, BORDER)
    s.text(330, 531, 'Việc cần xử lý', 21, BROWN, True, 700)
    s.line(304, 550, 1044, 550)
    for i, (title, description_row, status) in enumerate(rows):
        y = 580 + i * 75
        s.text(330, y, title, 14, BROWN, weight=700)
        s.text(330, y + 20, description_row, 11, MUTED)
        s.rect(900, y - 21, 110, 27, '#EEE0CC', 13)
        s.text(915, y - 3, status, 11, BURGUNDY, weight=700)
        s.line(304, y + 37, 1044, y + 37)
    s.rect(1064, 489, 340, 358, CARD, 10, BORDER)
    s.text(1090, 530, 'Ghi chú nghiệp vụ', 21, BROWN, True, 700)
    for i, line_text in enumerate(aside):
        s.text(1090, 570 + i * 25, line_text, 12, MUTED)
    s.rect(1090, 763, 224, 44, BURGUNDY, 7)
    s.text(1109, 792, 'Mở không gian làm việc →', 12, PAPER, weight=700)
    s.save(filename)


web_screen(
    'quan-tri-tong-quan.svg', 'Quản trị viên', 'Quản trị toàn hệ thống',
    'Toàn cảnh vận hành SMGS', 'Theo dõi tài khoản, bảo tàng và giao dịch của hệ thống trong một nơi.',
    ['Tổng quan hệ thống', 'Bảo tàng & Không gian', 'Kho hiện vật', 'Người dùng & Phân quyền', 'Dịch vụ số & giao dịch', 'Nhật ký hệ thống'],
    [('5', 'Tài khoản', 'Toàn hệ thống'), ('3', 'Bảo tàng', 'Đang kết nối'), ('176.000 đ', 'Doanh thu mô phỏng', 'Giao dịch thành công'), ('3', 'Chờ kiểm duyệt', 'Nội dung chưa xuất bản')],
    [('Gói Hành trình di sản nâng cao', 'Trần Ngọc Ánh · 27/09/2026', '59.000 đ'), ('Gói Hướng dẫn số Tiêu chuẩn', 'Lê Minh Hoàng · 27/09/2026', '29.000 đ'), ('Gói Gia đình và Nhóm', 'Nguyễn Văn Hùng · 27/09/2026', '119.000 đ')],
    ['3 nội dung đang chờ duyệt.', '0 giao dịch đang xử lý.', 'Theo dõi nhật ký hệ thống.'],
)
web_screen(
    'kiem-duyet-tong-quan.svg', 'Kiểm duyệt viên', 'Không gian kiểm duyệt',
    'Đưa nội dung tốt đến khách tham quan', 'Xem bản nháp, phản hồi và tiến độ phê duyệt trước khi xuất bản.',
    ['Tổng quan kiểm duyệt', 'Hàng đợi kiểm duyệt', 'Hiện vật & Thuyết minh', 'Đánh giá từ khách', 'Lịch sử phê duyệt'],
    [('2', 'Chờ duyệt', 'Cần xem nội dung'), ('0', 'Đã phê duyệt', 'Nội dung sẵn sàng'), ('0', 'Cần hiệu đính', 'Đã gửi góp ý'), ('1', 'Phản hồi mới', 'Khách đang chờ trả lời')],
    [('Thuyết minh thiếu nhi: Trống đồng Ngọc Lũ', 'Nguyễn Mai Anh · 27/09/2026', 'Chờ duyệt'), ('Câu hỏi tương tác: Thạp đồng Đào Thịnh', 'Lê Tuấn Kiệt · 27/09/2026', 'Chờ duyệt'), ('Đánh giá trải nghiệm tham quan', 'Khách tham quan · 27/09/2026', 'Cần trả lời')],
    ['Đọc bản nháp và đối chiếu tư liệu.', 'Yêu cầu sửa hoặc phê duyệt.', 'Theo dõi phản hồi của khách.'],
)
web_screen(
    'nhan-vien-tong-quan.svg', 'Nhân viên bảo tàng', 'Bàn làm việc bảo tàng',
    'Bàn làm việc bảo tàng', 'Cập nhật hiện vật, tạo nội dung số và chuẩn bị hành trình tham quan.',
    ['Bàn làm việc', 'Quản lý hiện vật & QR', 'Xưởng nội dung AI', 'Cấu trúc không gian', 'Hành trình & triển lãm'],
    [('4', 'Hiện vật', 'Bảo tàng đang chọn'), ('11.870', 'Lượt quét mã', 'Từ các hiện vật'), ('2', 'Bản gửi duyệt', 'Đang trong quy trình'), ('2', 'Hành trình mẫu', 'Sẵn sàng giới thiệu')],
    [('Trống đồng Ngọc Lũ', 'Phòng Văn hóa Đông Sơn', 'Đã xuất bản'), ('Thạp đồng Đào Thịnh', 'Phòng Văn hóa Đông Sơn', 'Đã xuất bản'), ('Bình gốm hoa nâu thời Lý', 'Phòng Triều đại Lý – Trần', 'Đã xuất bản')],
    ['Hoàn thiện hồ sơ và hình ảnh.', 'Tạo thuyết minh trước khi gửi duyệt.', 'Chuẩn bị hành trình tham quan.'],
)


def mobile_home():
    s = SVG(390, 844)
    s.rect(0, 0, 390, 844, PAPER)
    for y in range(33, 844, 34):
        s.line(0, y, 390, y, '#EDE0CE')
    s.rect(0, 0, 390, 6, BROWN)
    s.text(20, 42, 'THỨ NĂM, 27 THÁNG 9', 10, BURGUNDY, weight=700, spacing=1)
    s.text(20, 78, 'Chào buổi sáng, Nam', 27, BURGUNDY, True, 500)
    s.text(20, 101, 'Hôm nay bạn muốn khám phá điều gì?', 13, MUTED)
    s.circle(354, 62, 15, CARD, BORDER)
    s.text(349, 68, '●', 13, BURGUNDY)
    s.rect(20, 125, 350, 48, CARD, 8, BORDER)
    s.circle(43, 149, 7, 'none', BURGUNDY)
    s.text(60, 154, 'Tìm bảo tàng hoặc hiện vật', 13, MUTED)
    s.rect(20, 191, 350, 67, BURGUNDY, 8)
    s.rect(36, 207, 34, 34, BURGUNDY, 2, '#D9BFA0')
    s.text(45, 232, '▦', 20, PAPER)
    s.text(82, 220, 'Quét mã hiện vật', 15, PAPER, weight=700)
    s.text(82, 241, 'Dùng mã QR hoặc máy ảnh', 11, PAPER)
    s.text(343, 231, '→', 22, PAPER)
    s.text(20, 305, 'Bảo tàng nổi bật', 20, BURGUNDY, True, 500)
    s.text(333, 305, 'Xem tất cả', 11, BURGUNDY)
    s.line(20, 318, 370, 318)
    s.rect(20, 331, 350, 356, CARD, 8, BORDER)
    s.rect(21, 332, 348, 177, '#C7B59B', 6)
    s.rect(73, 388, 241, 121, '#A48D70')
    s.rect(106, 367, 174, 142, '#E8D3B3')
    s.rect(92, 356, 203, 17, BURGUNDY)
    s.rect(130, 383, 125, 126, '#DFC5A2')
    s.circle(192, 377, 56, 'none', '#8A604C')
    for x in (144, 177, 210, 243):
        s.rect(x, 424, 12, 85, '#85614E')
    s.text(35, 538, 'BẢO TÀNG QUỐC GIA', 11, BURGUNDY, weight=700, spacing=1)
    s.text(35, 566, 'Bảo tàng Lịch sử Quốc gia', 18, BURGUNDY, True, 500)
    s.text(35, 588, 'Hà Nội, Việt Nam', 11, MUTED)
    s.text(35, 617, 'Khám phá di sản Việt Nam qua các thời kỳ,', 12, BROWN)
    s.text(35, 634, 'từ buổi đầu dựng nước đến hiện đại.', 12, BROWN)
    s.rect(35, 648, 320, 28, PAPER, 5, BORDER)
    s.text(146, 667, 'Xem bảo tàng →', 12, BROWN, weight=700)
    s.text(20, 728, 'Vừa xem gần đây', 20, BURGUNDY, True, 500)
    s.rect(0, 774, 390, 70, CARD)
    s.line(0, 774, 390, 774, BORDER)
    for i, (icon, label) in enumerate([('⌂', 'Trang chủ'), ('◉', 'Khám phá'), ('▦', 'Quét mã'), ('◇', 'Hành trình'), ('♙', 'Cá nhân')]):
        x = 38 + i * 78
        s.text(x, 809, icon, 20, BURGUNDY if i == 0 else MUTED)
        s.text(x - 16, 830, label, 9, BURGUNDY if i == 0 else MUTED)
    s.save('khach-trang-chu.svg')


mobile_home()
print('Created 4 SVG screens in', ROOT)
