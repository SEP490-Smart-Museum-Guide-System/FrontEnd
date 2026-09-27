import fs from 'node:fs';
import path from 'node:path';

const dir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/(?:[A-Za-z]:)/, m => m.slice(1)));
const colors = { paper:'#F4EBDD', surface:'#F8F1E7', burgundy:'#6B2E2E', ink:'#3B302A', gold:'#B38B59', line:'#DACBB5', muted:'#5F4D44', white:'#F9F2E9', cool:'#F3F5F7' };
const esc = s => String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const rect = (x,y,w,h,fill,rx=0,stroke='none') => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" fill="${fill}" stroke="${stroke}"/>`;
const text = (x,y,s,size=16,fill=colors.ink,serif=false,weight='400') => `<text x="${x}" y="${y}" fill="${fill}" font-family="${serif?'Noto Serif':'Noto Sans'}" font-size="${size}" font-weight="${weight}">${esc(s)}</text>`;
const line = (x1,y1,x2,y2,color=colors.line) => `<path d="M${x1} ${y1}L${x2} ${y2}" stroke="${color}" stroke-width="1"/>`;
function wrap(s,n=36) {
  const words=String(s).split(' '), out=[]; let row='';
  for(const word of words){if((row+' '+word).trim().length>n){out.push(row);row=word}else row=(row+' '+word).trim()}
  if(row)out.push(row); return out.slice(0,3);
}
function lines(x,y,s,size,color,serif=false,max=36,step=size*1.55){
  return wrap(s,max).map((v,i)=>text(x,y+i*step,v,size,color,serif)).join('');
}
const mobile=[
 ['01','Đăng nhập','Chào mừng bạn trở lại','Đăng nhập để mở cánh cửa di sản.',['Email','Mật khẩu','Tài khoản mẫu theo vai trò'],'Đăng nhập'],
 ['02','Tạo tài khoản','Bắt đầu hành trình','Tạo tài khoản khách tham quan miễn phí.',['Họ và tên','Email','Mật khẩu'],'Tạo tài khoản'],
 ['03','Quên mật khẩu','Lấy lại quyền truy cập','Nhập email để thử khôi phục tài khoản.',['Email của bạn','Thông báo khôi phục'],'Tiếp tục'],
 ['04','Trang chủ','Chạm vào di sản','Một ngày mới, một câu chuyện mới.',['Bảo tàng nổi bật','Hiện vật kể chuyện','Một giờ cho di sản'],'Khám phá ngay'],
 ['05','Khám phá','Tìm một điểm đến','Tìm bảo tàng, hiện vật, chủ đề và phòng.',['Tìm kiếm','Bộ lọc khám phá','Bảo tàng Lịch sử Quốc gia'],'Xem bảo tàng'],
 ['06','Chi tiết bảo tàng','Bảo tàng Lịch sử Quốc gia','Một hành trình xuyên suốt lịch sử Việt Nam.',['Câu chuyện bảo tàng','Hành trình dành cho bạn','Vé & Hướng dẫn số'],'Khám phá hiện vật'],
 ['07','Bắt đầu khám phá','Mở câu chuyện hiện vật','Chọn cách bạn muốn bắt đầu.',['Quét mã hiện vật','Nhận diện qua hình ảnh','Xem danh sách hiện vật'],'Tiếp tục'],
 ['08','Quét mã hiện vật','Đưa mã vào khung quét','Mã ở bên cạnh hiện vật sẽ dẫn đến câu chuyện.',['Khung quét mô phỏng','Chọn hiện vật mẫu','Không tìm thấy mã'],'Xem kết quả'],
 ['09','Nhận diện qua ảnh','Khám phá bằng hình ảnh','Tìm hiện vật qua ảnh bạn chọn.',['Chọn ảnh mẫu','Đang nhận diện','Không nhận diện được'],'Thử nhận diện'],
 ['10','Danh sách hiện vật','Bộ sưu tập đang chờ','Duyệt theo phòng, thời kỳ và chủ đề.',['Trống đồng Ngọc Lũ','Áo Nhật Bình triều Nguyễn','Hiện vật khác'],'Xem hiện vật'],
 ['11','Chi tiết hiện vật','Trống đồng Ngọc Lũ','Âm vang Đông Sơn từ hàng nghìn năm trước.',['Câu chuyện hiện vật','Thuyết minh','Hướng dẫn viên AI'],'Xem mô hình 3D'],
 ['12','Hiện vật 3D','Quan sát từng chi tiết','Xoay và phóng to mô hình trống đồng.',['Mô hình 3D tương tác','Cách sử dụng','Thông tin hiện vật'],'Trở về câu chuyện'],
 ['13','Hướng dẫn viên AI','Cùng tìm lời giải','Đặt câu hỏi về hiện vật bạn đang xem.',['Câu hỏi gợi ý','Câu trả lời','Hỏi tiếp'],'Gửi câu hỏi'],
 ['14','Thuyết minh','Lắng nghe câu chuyện','Thuyết minh bằng văn bản và thanh phát mô phỏng.',['Giới thiệu hiện vật','Thanh điều khiển','Nội dung lời kể'],'Tạm dừng'],
 ['15','Thử tài','Bạn hiểu di sản đến đâu?','Trả lời câu hỏi về hiện vật.',['Câu hỏi 1 / 5','Chọn một đáp án','Giải thích sau khi chọn'],'Xác nhận đáp án'],
 ['16','Kết quả thử tài','Thêm một dấu mốc','Xem điểm, câu đúng và huy hiệu.',['Điểm của bạn','Huy hiệu vừa nhận','Xem lời giải'],'Thử lại'],
 ['17','Chọn hành trình','Đi theo điều bạn yêu thích','Một lộ trình vừa vặn với thời gian của bạn.',['Chọn bảo tàng','Thời gian tham quan','Sở thích khám phá'],'Gợi ý hành trình'],
 ['18','Lộ trình tham quan','Những điểm dừng của bạn','Theo dõi đường đi và tiến độ.',['Sơ đồ bảo tàng','Điểm hiện tại','Điểm tiếp theo'],'Bắt đầu hành trình'],
 ['19','Hành trình hoàn thành','Một chuyến đi đáng nhớ','Bạn đã ghé những điểm dừng thú vị.',['Số hiện vật đã xem','Điểm đã bỏ qua','Lưu vào lịch sử'],'Về trang chủ'],
 ['20','Hồ sơ','Câu chuyện của bạn','Theo dõi hành trình khám phá di sản.',['Lịch sử khám phá','Điểm & huy hiệu','Dịch vụ đã đăng ký'],'Cài đặt'],
 ['21','Lịch sử khám phá','Những ngày cùng di sản','Mỗi chuyến đi đều để lại một dấu mốc.',['Theo ngày','Theo bảo tàng','Các hiện vật đã xem'],'Xem chuyến đi'],
 ['22','Chi tiết chuyến đi','Một ngày ở bảo tàng','Hiện vật, hành trình và thử tài của ngày.',['Hiện vật đã xem','Hành trình','Kết quả thử tài'],'Gửi góp ý'],
 ['23','Vé & Hướng dẫn số','Chọn đúng gói cho chuyến đi','Vé, hướng dẫn số hoặc gói kết hợp.',['Vé tham quan','Hướng dẫn số','Gói kết hợp'],'Chọn sản phẩm'],
 ['24','Thanh toán mô phỏng','Hoàn tất đăng ký','Chọn ngày và phương thức thanh toán.',['Bảo tàng & ngày tham quan','VNPay / MoMo','Tóm tắt đơn hàng'],'Xác nhận mô phỏng'],
 ['25','Kết quả thanh toán','Quyền sử dụng của bạn','Xem kết quả và thử lại khi thất bại.',['Giao dịch thành công','Vé đã đăng ký','Trường hợp thất bại'],'Xem dịch vụ'],
 ['26','Góp ý & đánh giá','Kể lại trải nghiệm','Đánh giá chuyến đi và chia sẻ góp ý.',['Số sao đánh giá','Nội dung góp ý','Bảo tàng liên quan'],'Gửi góp ý'],
 ['27','Cài đặt','Theo cách bạn muốn','Điều chỉnh cỡ chữ và chuyển động.',['Cỡ chữ','Giảm chuyển động','Đăng xuất'],'Lưu cài đặt']
];
const web={
 curator:{role:'KIỂM DUYỆT VIÊN',menus:['Tổng quan','Nội dung bảo tàng','Nội dung AI','Kiểm duyệt','Xuất bản','Phản hồi & báo cáo'],desc:['Công việc trong ngày và hàng chờ cần xử lý.','Quản lý hiện vật, hình ảnh, thư viện và bản đồ.','Tạo thuyết minh và câu hỏi thử tài bằng AI.','Đọc, sửa, phê duyệt hoặc từ chối bản nháp.','Lên lịch và đưa nội dung đã duyệt đến khách.','Theo dõi đánh giá và báo cáo theo bảo tàng.']},
 staff:{role:'NHÂN VIÊN BẢO TÀNG',menus:['Tổng quan','Hiện vật','Hình ảnh & 3D','Phòng & bản đồ','Gửi kiểm duyệt','Phản hồi khách tham quan'],desc:['Nội dung trong phạm vi bảo tàng được giao.','Thêm hiện vật và cập nhật hồ sơ.','Tải hình ảnh, media và mô hình 3D.','Cập nhật phòng, khu vực và vị trí hiện vật.','Gửi nội dung mới đến người có quyền duyệt.','Theo dõi góp ý thuộc bảo tàng.']},
 admin:{role:'QUẢN TRỊ VIÊN',menus:['Tổng quan','Người dùng','Vai trò & phân quyền','Bảo tàng & nhân sự','Thương mại','Nhật ký hệ thống','Cài đặt'],desc:['Theo dõi tình trạng toàn hệ thống.','Quản lý tài khoản và trạng thái truy cập.','Thiết lập quyền theo trách nhiệm.','Quản lý đơn vị và phân công nhân viên.','Đơn mua, thanh toán, hoàn tiền, hóa đơn, doanh thu.','Tra cứu các thay đổi quan trọng.','Cấu hình vận hành hệ thống.']}
};
function mobileSvg(d){
 const [no,label,title,subtitle,cards,action]=d; let out='';
 out+=rect(0,0,390,844,colors.paper)+rect(0,0,390,7,colors.burgundy);
 out+=text(22,39,'SMGS  /  '+label.toUpperCase(),11,colors.burgundy,false,'700');
 out+=lines(22,85,title,29,colors.ink,true,23,38);
 out+=lines(22,129,subtitle,14,colors.muted,false,46,21);
 out+=rect(22,182,346,170,colors.burgundy,14);
 out+=`<circle cx="326" cy="206" r="55" fill="${colors.gold}" fill-opacity=".23"/><circle cx="343" cy="237" r="84" fill="none" stroke="${colors.gold}" stroke-opacity=".5"/>`;
 out+=text(44,223,no+'  /  CẨM NANG DI SẢN',12,colors.white,false,'700');
 out+=lines(44,267,label==='Trang chủ'?'Hẹn bạn ở bảo tàng':title,22,colors.white,true,25,32);
 out+=text(44,325,'KHÁM PHÁ THEO CÁCH CỦA BẠN  →',10,colors.white,false,'700');
 let y=378;
 for(let i=0;i<cards.length;i++){out+=rect(22,y,346,84,colors.surface,10,colors.line);out+=rect(22,y,4,84,colors.gold,2);out+=text(42,y+26,String(i+1).padStart(2,'0'),12,colors.gold,false,'700');out+=lines(76,y+28,cards[i],18,colors.burgundy,true,27,22);let detail=cards[i]==='Email'?'Nhập địa chỉ email của bạn.':cards[i]==='Mật khẩu'?'Nhập mật khẩu tài khoản.':cards[i].includes('Tài khoản mẫu')?'Xem thử giao diện của từng vai trò.':'Chạm để xem chi tiết và tiếp tục hành trình.';out+=text(76,y+60,detail,11,colors.muted);y+=96}
 out+=rect(22,y+8,346,48,colors.burgundy,8)+text(42,y+39,action+'  →',15,colors.white,false,'700');
 out+=line(0,768,390,768)+rect(0,769,390,75,colors.surface);
 ['Trang chủ','Khám phá','Quét mã','Hành trình','Cá nhân'].forEach((v,i)=>{out+=`<circle cx="${39+i*78}" cy="792" r="7" fill="${['Trang chủ','Khám phá','Quét mã','Hành trình','Cá nhân'].indexOf(label)>=0&&label===v?colors.burgundy:colors.gold}"/>`;out+=text(17+i*78,819,v,9,colors.muted)});
 return `<svg xmlns="http://www.w3.org/2000/svg" width="390" height="844" viewBox="0 0 390 844">${out}</svg>`;
}
function webSvg(role,menu,desc,index){
 const W=1440,H=900,bg=role==='admin'?colors.cool:colors.paper;let out=rect(0,0,W,H,bg);
 out+=rect(0,0,252,H,colors.ink)+rect(0,0,252,7,colors.gold)+text(28,65,'SMGS',28,colors.white,true)+text(28,91,'KHÔNG GIAN NGHIỆP VỤ',10,colors.gold,false,'700');
 web[role].menus.forEach((m,i)=>{let y=154+i*63;if(i===index)out+=rect(16,y-28,220,44,colors.burgundy,8);out+=text(34,y,m,14,i===index?colors.white:colors.paper,false,i===index?'700':'400')});
 out+=text(28,851,web[role].role,11,colors.gold,false,'700');
 out+=rect(252,0,1188,88,colors.surface)+text(292,55,'SMGS  /  '+web[role].role,13,colors.burgundy,false,'700')+text(1225,55,'TÀI KHOẢN  ◦',12,colors.muted);
 out+=text(292,151,'KHÔNG GIAN LÀM VIỆC',12,colors.burgundy,false,'700');
 out+=text(292,203,menu,34,colors.ink,true);
 out+=text(292,241,desc,16,colors.muted);
 const labels=role==='admin'?['Người dùng','Bảo tàng','Giao dịch','Hoạt động']:role==='curator'?['Chờ kiểm duyệt','Đã duyệt','Cần chỉnh sửa','Đánh giá']:['Hiện vật','Tư liệu','Bản nháp','Góp ý'];
 const vals=role==='admin'?['1.284','06','48,6 tr','98,7%']:role==='curator'?['12','38','07','4,8']:['96','32','06','4,7'];
 labels.forEach((l,i)=>{let x=292+i*276;out+=rect(x,282,256,125,colors.surface,12,colors.line);out+=text(x+20,325,vals[i],28,colors.burgundy,true);out+=text(x+20,371,l,14,colors.muted)});
 out+=rect(292,438,691,345,colors.surface,12,colors.line)+rect(1003,438,397,345,colors.surface,12,colors.line);
 out+=text(315,478,role==='admin'?'Danh sách quản trị':'Danh sách làm việc',22,colors.ink,true)+text(1025,478,'Cần chú ý',22,colors.ink,true);
 const rows=role==='admin'?['Tài khoản và quyền truy cập','Phân công nhân sự bảo tàng','Đơn mua cần theo dõi','Cấu hình hệ thống']:role==='curator'?['Trống đồng Ngọc Lũ','Áo Nhật Bình triều Nguyễn','Bản đồ tầng 2','Thuyết minh mới']:['Hồ sơ hiện vật mới','Mô hình trống đồng 3D','Cập nhật phòng trưng bày','Gửi bản nháp duyệt'];
 rows.forEach((r,i)=>{let y=535+i*58;out+=line(315,y+14,958,y+14)+text(325,y+45,r,15,colors.ink)+text(890,y+45,'Xem →',12,colors.burgundy,false,'700')});
 ['01  Xem nội dung ưu tiên','02  Kiểm tra trạng thái','03  Tiếp tục công việc'].forEach((r,i)=>{out+=rect(1025,513+i*77,352,60,bg,8)+text(1042,551+i*77,r,14,colors.ink)});
 out+=text(292,847,'BẢN GIAO DIỆN THỬ  ·  NỘI DUNG MẪU CHƯA KẾT NỐI MÁY CHỦ',11,colors.muted);
 return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${out}</svg>`;
}
const manifest=[];
mobile.forEach((d,i)=>{const file=`mobile-${String(i+1).padStart(2,'0')}.svg`;fs.writeFileSync(path.join(dir,file),mobileSvg(d));manifest.push({file,page:'Khách tham quan · Mobile',screen:d[1]})});
for(const [role,data] of Object.entries(web))data.menus.forEach((menu,i)=>{const file=`${role}-${String(i+1).padStart(2,'0')}.svg`;fs.writeFileSync(path.join(dir,file),webSvg(role,menu,data.desc[i],i));manifest.push({file,page:role==='curator'?'Kiểm duyệt viên · Web':'Nhân viên bảo tàng · Web',screen:menu,role:data.role})});
fs.writeFileSync(path.join(dir,'manifest.json'),JSON.stringify(manifest,null,2));
const groups=[
  ['Khách tham quan · Điện thoại',manifest.filter(x=>x.file.startsWith('mobile-'))],
  ['Kiểm duyệt viên · Web',manifest.filter(x=>x.file.startsWith('curator-'))],
  ['Nhân viên bảo tàng · Web',manifest.filter(x=>x.file.startsWith('staff-'))],
  ['Quản trị viên · Web',manifest.filter(x=>x.file.startsWith('admin-'))]
];
const gallery=groups.map(([name,items])=>`<section><h2>${esc(name)} <small>${items.length} màn hình</small></h2><div class="grid">${items.map(x=>`<figure><img src="${x.file}" alt="${esc(x.screen)}"><figcaption>${esc(x.screen)}</figcaption></figure>`).join('')}</div></section>`).join('');
fs.writeFileSync(path.join(dir,'index.html'),`<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SMGS · Bộ màn hình</title><style>body{margin:0;background:#e9dfd1;color:#3B302A;font:15px 'Noto Sans',sans-serif}header{padding:34px 5vw;background:#6B2E2E;color:#F9F2E9}h1{font:500 35px 'Noto Serif',serif;margin:0 0 7px}p{margin:0}section{padding:22px 5vw}h2{font:500 25px 'Noto Serif',serif}small{font:13px 'Noto Sans',sans-serif;color:#6B2E2E}.grid{display:flex;gap:25px;overflow-x:auto;padding:10px 0 24px}figure{margin:0;flex:none}img{height:420px;width:auto;box-shadow:0 12px 28px #3b302a26;background:white}figcaption{padding:10px 0;font-weight:700}</style><header><h1>SMGS · Bộ màn hình giao diện</h1><p>46 màn hình vector theo các vai trò hiện có trong mã nguồn.</p></header>${gallery}</html>`);
console.log(`Đã tạo ${manifest.length} màn hình SVG trong ${dir}`);
