// Isolated AI / 3D examples. Never used as API fallbacks or business records.
export const aiDemoArtifacts = [
  {
    id: 'art-001',
    code: 'SMGS-ART-001',
    qrCode: 'SMGS-QR-VNMH-001',
    name: 'Trống đồng Ngọc Lũ',
    altName: 'Ngọc Lũ Bronze Drum',
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    buildingId: 'bld-01',
    buildingName: 'Tòa nhà A',
    floorId: 'flr-01',
    floorName: 'Tầng 1',
    galleryId: 'gal-01',
    galleryName: 'Phòng Văn hóa Đông Sơn',
    theme: 'Đông Sơn & Thời đại Kim khí',
    period: 'Văn hóa Đông Sơn (Thế kỷ II - III TCN)',
    dating: 'Khoảng 2.500 năm trước',
    material: 'Hợp kim đồng',
    dimensions: 'Đường kính mặt: 79.3 cm — Chiều cao: 63 cm — Trọng lượng: 86 kg',
    isNationalTreasure: true,
    has3DModel: true,
    modelUrl: '/assets/models/trong_dong_dong_son.glb',
    image: '/assets/images/ngoc-lu-web.jpg',
    referenceImages: [
      '/assets/images/ngoc-lu-web.jpg',
      '/assets/images/national-museum-web.jpg'
    ],
    audioDuration: '04:15',
    audioUrl: '/assets/audio/ngoc_lu_vn.mp3',
    status: 'published', // content_status: draft | pending_review | published | rejected | archived
    viewsCount: 14250,
    quizPassRate: '88.5%',
    shortDesc: 'Bảo vật quốc gia tiêu biểu nhất của nền văn hóa Đông Sơn, phản ánh đỉnh cao nghệ thuật đúc đồng và đời sống tâm linh, nông nghiệp của người Việt cổ.',
    fullDesc: `Trống đồng Ngọc Lũ là một trong những hiện vật khảo cổ học hoàn hảo và nguyên vẹn nhất của nền văn minh Đông Sơn được tìm thấy tại Việt Nam.

Mặt trống chính giữa đúc nổi hình ngôi sao 14 cánh biểu tượng của thần Mặt Trời - nguồn sống của cư dân nông nghiệp lúa nước. Xen giữa các cánh sao là hoa văn lông công tinh xảo.

Mặt trống gồm 16 vành hoa văn đồng tâm: vành hình học, chim Lạc bay ngược chiều kim đồng hồ, và đặc biệt là vành lễ hội mô tả sinh động cảnh người giã gạo, múa vũ trang, đánh trống đồng và nhà sàn truyền thống.

Thân trống chia làm ba phần: tang trống phình rộng khắc hình 6 chiếc thuyền chiến chở chiến binh; lưng trống hình trụ khắc hình dũng sĩ tay cầm rìu, giáo múa; chân trống xòe rộng để giữ độ vững chãi khi gõ.`,
    multilingual: {
      en: {
        name: 'Ngoc Lu Bronze Drum',
        period: 'Dong Son Culture (2nd - 3rd Century BC)',
        shortDesc: 'The most iconic National Treasure of Vietnam Dong Son Culture, showcasing the pinnacle of ancient metallurgy, spiritual life, and early agricultural civilization.'
      },
      fr: {
        name: 'Tambour de bronze de Ngoc Lu',
        period: 'Culture de Dong Son (IIe - IIIe siècle av. J.-C.)',
        shortDesc: 'Chef-d’œuvre absolu et Trésor National de la culture de Dong Son, illustrant la maîtrise métallurgique exceptionnelle du Vietnam antique.'
      },
      ja: {
        name: 'ゴックルー銅鼓 (ドンソン文化)',
        period: 'ドンソン文化 (紀元前2〜3世紀)',
        shortDesc: 'ベトナムのドンソン文化を代表する国宝であり、古代の高度な青銅鋳造技術と農耕儀礼を伝えています。'
      }
    },
    quizzes: [
      {
        id: 'q-01',
        question: 'Ngôi sao ở tâm mặt Trống đồng Ngọc Lũ có bao nhiêu cánh?',
        options: ['12 cánh', '14 cánh', '16 cánh', '18 cánh'],
        correctIndex: 1,
        explanation: 'Ngôi sao ở tâm mặt Trống đồng Ngọc Lũ có đúng 14 cánh biểu trưng cho ánh sáng và mặt trời.'
      },
      {
        id: 'q-02',
        question: 'Loài chim huyền thoại nào bay ngược chiều kim đồng hồ trên các vành đai trống?',
        options: ['Chim Lạc', 'Chim Phượng hoàng', 'Chim Công', 'Chim Én'],
        correctIndex: 0,
        explanation: 'Chim Lạc là biểu tượng thiêng liêng xuất hiện chủ đạo trên mặt trống đồng Đông Sơn.'
      },
      {
        id: 'q-03',
        question: 'Hình ảnh nào trên tang Trống đồng Ngọc Lũ thể hiện truyền thống thủy chiến của người Việt cổ?',
        options: ['Những con thuyền rồng chở chiến binh', 'Cảnh săn hươu trên cạn', 'Cảnh giã lúa', 'Cảnh hát đối đáp'],
        correctIndex: 0,
        explanation: 'Tang trống khắc nổi 6 chiếc thuyền chiến lướt sóng chở đầy chiến binh mang rìu giáo và cung nỏ.'
      }
    ]
  },
  {
    id: 'art-002',
    code: 'SMGS-ART-002',
    qrCode: 'SMGS-QR-VNMH-002',
    name: 'Thạp đồng Đào Thịnh',
    altName: 'Dao Thinh Bronze Jar',
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    buildingId: 'bld-01',
    buildingName: 'Tòa nhà A',
    floorId: 'flr-01',
    floorName: 'Tầng 1',
    galleryId: 'gal-01',
    galleryName: 'Phòng Văn hóa Đông Sơn',
    theme: 'Đông Sơn & Thời đại Kim khí',
    period: 'Văn hóa Đông Sơn (Thế kỷ V - III TCN)',
    dating: 'Khoảng 2.500 năm trước',
    material: 'Hợp kim Đồng',
    dimensions: 'Chiều cao: 98 cm — Đường kính miệng: 61 cm',
    isNationalTreasure: true,
    has3DModel: false,
    modelUrl: '',
    image: '/assets/images/national-museum-web.jpg',
    referenceImages: ['/assets/images/national-museum-web.jpg'],
    audioDuration: '03:40',
    audioUrl: '',
    status: 'published',
    viewsCount: 9320,
    quizPassRate: '82.0%',
    shortDesc: 'Chiếc thạp đồng lớn nhất, nguyên vẹn nhất thuộc nền văn hóa Đông Sơn, mang ý niệm phồn thực sinh sôi và kỹ thuật đúc tượng khối tròn độc đáo.',
    fullDesc: 'Thạp đồng Đào Thịnh được phát hiện tại Yên Bái năm 1961. Nắp thạp có 4 khối tượng đôi nam nữ đang giao hoan - biểu tượng phồn thực thiêng liêng cầu mong mùa màng tốt tươi và sự trường tồn của bộ tộc. Thân thạp trang trí 25 vành hoa văn tinh tế gồm cá sấu, thuyền buồm, chim Lạc và hình học zíc zắc.',
    multilingual: {
      en: {
        name: 'Dao Thinh Bronze Jar',
        period: 'Dong Son Culture (5th - 3rd Century BC)',
        shortDesc: 'The largest and most ornate bronze jar of Dong Son civilization, renowned for its fertility symbolism and mastery of bronze sculpting.'
      }
    },
    quizzes: [
      {
        id: 'q-04',
        question: 'Điểm độc đáo nhất trên nắp Thạp đồng Đào Thịnh là gì?',
        options: ['4 tượng đôi nam nữ biểu tượng phồn thực', 'Tượng rồng chầu mặt trời', 'Tượng chim bồ câu ngậm ngọc', 'Tượng voi chiến bốn ngà'],
        correctIndex: 0,
        explanation: '4 khối tượng tròn gắn trên nắp thạp thể hiện tín ngưỡng phồn thực nguyên thủy của cư dân Đông Sơn.'
      }
    ]
  },
  {
    id: 'art-003',
    code: 'SMGS-ART-003',
    qrCode: 'SMGS-QR-VNMH-003',
    name: 'Tượng Phật Quan Âm Nghìn Mắt Nghìn Tay',
    altName: 'Thousand-Armed Guanyin Statue',
    museumId: 'mus-03',
    museumName: 'Bảo tàng Mỹ thuật Việt Nam',
    buildingId: 'bld-04',
    buildingName: 'Tòa nhà Cổ điển',
    floorId: 'flr-05',
    floorName: 'Tầng 1',
    galleryId: 'gal-10',
    galleryName: 'Phòng Tượng Phật & Nghệ thuật Chùa chiền',
    theme: 'Mỹ thuật Phật giáo',
    period: 'Thời Lê Trung Hưng (Năm 1656)',
    dating: 'Thế kỷ XVII',
    material: 'Gỗ mít phủ sơn son thếp vàng',
    dimensions: 'Chiều cao cả tòa sen: 3.7 m',
    isNationalTreasure: true,
    has3DModel: false,
    modelUrl: '',
    image: '/assets/images/ngoc-lu-web.jpg',
    referenceImages: ['/assets/images/ngoc-lu-web.jpg'],
    audioDuration: '05:10',
    audioUrl: '',
    status: 'published',
    viewsCount: 11200,
    quizPassRate: '91.2%',
    shortDesc: 'Đỉnh cao kiệt tác điêu khắc Phật giáo Việt Nam thế kỷ XVII do nghệ nhân Trương Thọ Nam tạc, kết hợp hài hòa giữa triết lý Phật pháp và tâm hồn dân tộc.',
    fullDesc: 'Pho tượng có 42 cánh tay lớn kết các ấn pháp và 952 cánh tay nhỏ tạo thành vầng hào quang tỏa sáng xung quanh. Trong mỗi lòng bàn tay có một con mắt biểu thị trí tuệ thấu suốt muôn loài và lòng từ bi cứu độ vô biên.',
    multilingual: {
      en: {
        name: 'Statue of Avalokiteshvara (Thousand Arms & Eyes)',
        period: 'Le Revival Dynasty (1656)',
        shortDesc: 'A masterpiece of 17th-century Vietnamese Buddhist sculpture, embodying ultimate compassion and wisdom.'
      }
    },
    quizzes: []
  },
  {
    id: 'art-004',
    code: 'SMGS-ART-004',
    qrCode: 'SMGS-QR-VNMH-004',
    name: 'Bình Gốm Hoa Nâu Thời Lý',
    altName: 'Ly Dynasty Brown Pattern Ceramic Vase',
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    buildingId: 'bld-01',
    buildingName: 'Tòa nhà A',
    floorId: 'flr-02',
    floorName: 'Tầng 2',
    galleryId: 'gal-04',
    galleryName: 'Phòng Triều đại Ngô - Đinh - Tiền Lê - Lý - Trần',
    theme: 'Đại Việt nghìn năm',
    period: 'Thời Lý (Thế kỷ XI - XII)',
    dating: 'Thế kỷ XI',
    material: 'Gốm men tro men hoa nâu',
    dimensions: 'Chiều cao: 42 cm — Đường kính miệng: 18 cm',
    isNationalTreasure: false,
    has3DModel: false,
    modelUrl: '',
    image: '/assets/images/national-museum-web.jpg',
    referenceImages: ['/assets/images/national-museum-web.jpg'],
    audioDuration: '02:50',
    audioUrl: '',
    status: 'published',
    viewsCount: 5400,
    quizPassRate: '79.5%',
    shortDesc: 'Tác phẩm gốm men tiêu biểu cho dòng gốm hoa nâu đặc sắc thời Lý với hoa văn hoa sen, lá đề và chiến binh múa khiên.',
    fullDesc: 'Gốm hoa nâu là dòng gốm thuần Việt rực rỡ dưới thời Lý - Trần. Kỹ thuật cạo men để lộ xương gốm rồi tô men màu nâu sắt tạo nên sự tương phản mộc mạc mà khỏe khoắn.',
    multilingual: {
      en: {
        name: 'Ly Dynasty Brown-Patterned Ceramic Jar',
        period: 'Ly Dynasty (11th - 12th Century)',
        shortDesc: 'Exquisite ceramic artifact featuring lotus motifs and warriors carved in iron-brown slip under clear glaze.'
      }
    },
    quizzes: []
  },
  {
    id: 'art-005',
    code: 'SMGS-ART-005',
    qrCode: 'SMGS-QR-VNMH-005',
    name: 'Trống Đồng Cảnh Thịnh',
    altName: 'Canh Thinh Bronze Drum',
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    buildingId: 'bld-01',
    buildingName: 'Tòa nhà A',
    floorId: 'flr-02',
    floorName: 'Tầng 2',
    galleryId: 'gal-05',
    galleryName: 'Phòng Triều đại Hậu Lê - Mạc - Tây Sơn - Nguyễn',
    theme: 'Di sản Hoàng triều',
    period: 'Thời Tây Sơn (Năm 1800)',
    dating: 'Năm Cảnh Thịnh thứ 8 (1800)',
    material: 'Đồng đúc nguyên khối',
    dimensions: 'Đường kính: 54.3 cm — Chiều cao: 37.4 cm',
    isNationalTreasure: true,
    has3DModel: false,
    modelUrl: '',
    image: '/assets/images/national-museum-web.jpg',
    referenceImages: ['/assets/images/national-museum-web.jpg'],
    audioDuration: '03:15',
    audioUrl: '',
    status: 'published',
    viewsCount: 6800,
    quizPassRate: '84.1%',
    shortDesc: 'Bảo vật quốc gia thời Tây Sơn đúc phỏng theo mẫu trống đồng thời Hán nhưng mang văn khắc chữ Hán ca ngợi công đức và Phật pháp.',
    fullDesc: 'Trống đồng Cảnh Thịnh do người phụ nữ họ Nguyễn đúc cúng dường chùa Linh Trường vào năm 1800 dưới triều vua Cảnh Thịnh thời Tây Sơn. Khắp mặt và thân trống đúc nổi hoa văn rồng mây, sóng nước và bài văn bia chữ Hán dài 272 chữ.',
    multilingual: {},
    quizzes: []
  }
];

