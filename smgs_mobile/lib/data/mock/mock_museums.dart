import '../../models/museum.dart';

const List<Museum> mockMuseums = [
  Museum(
    id: 'museum_national',
    name: 'Bảo tàng Lịch sử Quốc gia',
    location: 'Hoàn Kiếm, Hà Nội',
    description: 'Theo dấu những lớp trầm tích văn hóa, từ thời dựng nước đến những triều đại phong kiến. Mỗi hiện vật mở ra một góc nhìn về đời sống, tín ngưỡng và bàn tay tài hoa của người Việt.',
    imageUrl: '',
    openingHours: '08:00 – 17:00',
    category: 'Lịch sử',
    shortIntro: 'Một hành trình qua những dấu mốc văn hóa và lịch sử Việt Nam.',
  ),
  Museum(
    id: 'museum_ho_chi_minh',
    name: 'Bảo tàng Hồ Chí Minh',
    location: 'Ba Đình, Hà Nội',
    description: 'Tìm hiểu cuộc đời, sự nghiệp của Chủ tịch Hồ Chí Minh qua các tư liệu và câu chuyện gắn với lịch sử dân tộc.',
    imageUrl: '',
    openingHours: '08:00 – 16:30',
    category: 'Văn hóa',
    shortIntro: 'Những câu chuyện về một cuộc đời gắn liền với dân tộc.',
  ),
];
