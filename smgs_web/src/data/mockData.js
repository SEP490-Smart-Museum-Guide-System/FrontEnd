// Dữ liệu mẫu cho cổng nghiệp vụ SMGS (bảo tàng, hệ thống, quản trị)

export const initialMuseums = [
  {
    id: 'mus-01',
    name: 'Bảo tàng Lịch sử Quốc gia',
    shortName: 'BT Lịch sử QG',
    code: 'VNMH',
    address: 'Số 1 Tràng Tiền & 216 Trần Quang Khải, Hoàn Kiếm, Hà Nội',
    image: '/assets/images/national-museum-web.jpg',
    artifactCount: 142,
    visitorCountToday: 1280,
    status: 'active',
    description: 'Nơi lưu giữ, bảo tồn và phát huy di sản văn hóa, lịch sử hàng nghìn năm của dân tộc Việt Nam với hơn 200.000 hiện vật quý hiếm.',
    buildings: [
      {
        id: 'bld-01',
        name: 'Tòa nhà A (Số 1 Tràng Tiền)',
        code: 'A',
        floors: [
          {
            id: 'flr-01',
            name: 'Tầng 1 — Tiền sử & Sơ sử',
            number: 1,
            galleries: [
              { id: 'gal-01', name: 'Phòng Văn hóa Đông Sơn', code: 'A1-DS', artifactCount: 38, theme: 'Đông Sơn & Thời đại Kim khí' },
              { id: 'gal-02', name: 'Phòng Văn hóa Sa Huỳnh — Champa', code: 'A1-SH', artifactCount: 24, theme: 'Văn hóa Cổ phương Nam' },
              { id: 'gal-03', name: 'Sảnh Trưng bày Chuyên đề A', code: 'A1-HALL', artifactCount: 12, theme: 'Triển lãm Đặc biệt' },
            ]
          },
          {
            id: 'flr-02',
            name: 'Tầng 2 — Thời kỳ Phong kiến Độc lập',
            number: 2,
            galleries: [
              { id: 'gal-04', name: 'Phòng Triều đại Ngô - Đinh - Tiền Lê - Lý - Trần', code: 'A2-LT', artifactCount: 45, theme: 'Đại Việt nghìn năm' },
              { id: 'gal-05', name: 'Phòng Triều đại Hậu Lê - Mạc - Tây Sơn - Nguyễn', code: 'A2-HN', artifactCount: 35, theme: 'Di sản Hoàng triều' },
            ]
          }
        ]
      },
      {
        id: 'bld-02',
        name: 'Tòa nhà B (Số 216 Trần Quang Khải)',
        code: 'B',
        floors: [
          {
            id: 'flr-03',
            name: 'Tầng 1 — Lịch sử Cận Hiện đại (1858 - 1945)',
            number: 1,
            galleries: [
              { id: 'gal-06', name: 'Phòng Phong trào Cần Vương & Khởi nghĩa', code: 'B1-CV', artifactCount: 28, theme: 'Kháng chiến chống Pháp' },
            ]
          }
        ]
      }
    ]
  },
  {
    id: 'mus-02',
    name: 'Bảo tàng Hồ Chí Minh',
    shortName: 'BT Hồ Chí Minh',
    code: 'HCM-MUS',
    address: 'Số 19 Ngọc Hà, Ba Đình, Hà Nội',
    image: '/assets/images/ho-chi-minh-museum-web.jpg',
    artifactCount: 86,
    visitorCountToday: 2450,
    status: 'active',
    description: 'Trung tâm nghiên cứu, giới thiệu về cuộc đời, sự nghiệp của Chủ tịch Hồ Chí Minh và lịch sử đấu tranh giải phóng dân tộc.',
    buildings: [
      {
        id: 'bld-03',
        name: 'Tòa nhà Chính',
        code: 'MAIN',
        floors: [
          {
            id: 'flr-04',
            name: 'Tầng 2 — Không gian Trưng bày Tiểu sử',
            number: 2,
            galleries: [
              { id: 'gal-07', name: 'Phòng Thời niên thiếu & Quê hương', code: 'M2-QT', artifactCount: 30, theme: 'Thời niên thiếu' },
              { id: 'gal-08', name: 'Phòng Hành trình Tìm đường cứu nước', code: 'M2-TC', artifactCount: 42, theme: 'Hành trình 30 năm' },
            ]
          }
        ]
      }
    ]
  },
  {
    id: 'mus-03',
    name: 'Bảo tàng Mỹ thuật Việt Nam',
    shortName: 'BT Mỹ thuật VN',
    code: 'VNFA',
    address: 'Số 66 Nguyễn Thái Học, Ba Đình, Hà Nội',
    image: '/assets/images/ngoc-lu-web.jpg',
    artifactCount: 65,
    visitorCountToday: 730,
    status: 'active',
    description: 'Bảo tàng lưu giữ các tác phẩm nghệ thuật tạo hình, điêu khắc, hội họa tiêu biểu của mỹ thuật Việt Nam qua các thời kỳ.',
    buildings: [
      {
        id: 'bld-04',
        name: 'Tòa nhà Cổ điển',
        code: 'VFA-A',
        floors: [
          {
            id: 'flr-05',
            name: 'Tầng 1 — Mỹ thuật Cổ & Tôn giáo',
            number: 1,
            galleries: [
              { id: 'gal-09', name: 'Phòng Điêu khắc Gỗ đình làng', code: 'V1-DK', artifactCount: 25, theme: 'Điêu khắc Cổ truyền' },
              { id: 'gal-10', name: 'Phòng Tượng Phật & Nghệ thuật Chùa chiền', code: 'V1-TP', artifactCount: 20, theme: 'Mỹ thuật Phật giáo' },
            ]
          }
        ]
      }
    ]
  }
];

export const initialArtifacts = [
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
    status: 'published', // published | pending | draft
    viewsCount: 14250,
    scansCount: 4890,
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
    scansCount: 3120,
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
    scansCount: 4100,
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
    scansCount: 1650,
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
    scansCount: 2210,
    quizPassRate: '84.1%',
    shortDesc: 'Bảo vật quốc gia thời Tây Sơn đúc phỏng theo mẫu trống đồng thời Hán nhưng mang văn khắc chữ Hán ca ngợi công đức và Phật pháp.',
    fullDesc: 'Trống đồng Cảnh Thịnh do người phụ nữ họ Nguyễn đúc cúng dường chùa Linh Trường vào năm 1800 dưới triều vua Cảnh Thịnh thời Tây Sơn. Khắp mặt và thân trống đúc nổi hoa văn rồng mây, sóng nước và bài văn bia chữ Hán dài 272 chữ.',
    multilingual: {},
    quizzes: []
  }
];

export const initialTours = [
  {
    id: 'tour-01',
    code: 'TOUR-HERITAGE-01',
    title: 'Hành trình Bảo vật Quốc gia nghìn năm',
    duration: '90 phút',
    stopsCount: 8,
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    theme: 'Bảo vật Quốc gia',
    isPaidGuide: true,
    price: 39000,
    status: 'published',
    rating: 4.9,
    reviewsCount: 342,
    artifacts: ['art-001', 'art-002', 'art-004', 'art-005'],
    description: 'Chiêm ngưỡng trọn vẹn những bảo vật quốc gia vô giá từ buổi bình minh dựng nước của các vua Hùng đến thời đại phong kiến hoàng kim.'
  },
  {
    id: 'tour-02',
    code: 'TOUR-DONGSON-02',
    title: 'Tinh hoa Văn hóa Đông Sơn & Thời đại Đồ đồng',
    duration: '45 phút',
    stopsCount: 5,
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    theme: 'Đông Sơn',
    isPaidGuide: false,
    price: 0,
    status: 'published',
    rating: 4.8,
    reviewsCount: 189,
    artifacts: ['art-001', 'art-002'],
    description: 'Khám phá thế giới tâm linh, nghệ thuật quân sự và tài năng luyện kim siêu đẳng của người Việt cổ cách đây hơn 2.000 năm.'
  },
  {
    id: 'tour-03',
    code: 'TOUR-BUDDHIST-03',
    title: 'Dấu ấn Mỹ thuật Phật giáo Việt Nam qua các triều đại',
    duration: '60 phút',
    stopsCount: 6,
    museumId: 'mus-03',
    museumName: 'Bảo tàng Mỹ thuật Việt Nam',
    theme: 'Mỹ thuật Cổ truyền',
    isPaidGuide: true,
    price: 29000,
    status: 'published',
    rating: 4.95,
    reviewsCount: 120,
    artifacts: ['art-003'],
    description: 'Hành trình tìm hiểu các tuyệt tác điêu khắc tượng Phật gỗ, tượng đá và phù điêu đình chùa rực rỡ từ thế kỷ XI đến thế kỷ XVIII.'
  }
];

export const initialExhibitions = [
  {
    id: 'exh-01',
    title: 'Âm vang Đông Sơn — Kỷ nguyên kim khí rực rỡ',
    status: 'active',
    startDate: '2026-09-01',
    endDate: '2026-12-31',
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    location: 'Tòa nhà A — Sảnh Trưng bày Chuyên đề A & Phòng Đông Sơn',
    curatorName: 'TS. Trần Văn Phong',
    artifactsCount: 42,
    description: 'Triển lãm chuyên đề kỷ niệm 100 năm phát hiện và nghiên cứu nền Văn hóa Đông Sơn (1924 - 2024/2026).'
  },
  {
    id: 'exh-02',
    title: 'Sắc Gốm Đại Việt qua ngàn năm thăng trầm',
    status: 'upcoming',
    startDate: '2026-11-15',
    endDate: '2027-02-28',
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    location: 'Tòa nhà A — Tầng 2',
    curatorName: 'ThS. Phạm Bích Ngọc',
    artifactsCount: 60,
    description: 'Trưng bày bộ sưu tập gốm men Lý - Trần - Lê - Mạc - Nguyễn với các dòng men ngọc, men trắng, hoa nâu và hoa lam.'
  }
];

export const initialCurationQueue = [
  {
    id: 'cur-001',
    type: 'audio_narration', // audio_narration | quiz | artifact_update | new_tour
    title: 'Thuyết minh AI Trẻ em: Trống đồng Ngọc Lũ',
    targetArtifactId: 'art-001',
    targetArtifactName: 'Trống đồng Ngọc Lũ',
    submittedBy: 'Nguyễn Mai Anh (Nhân viên bảo tàng)',
    submittedDate: '2026-09-27 14:30',
    status: 'pending', // pending | approved | rejected | revision_requested
    priority: 'high',
    currentVersion: 'Bản thuyết minh chuẩn người lớn (04:15)',
    proposedContent: `Chào các bạn nhỏ! Hôm nay chúng mình cùng bước vào cỗ máy thời gian trở về hơn 2.500 năm trước để gặp "Ông Vua Trống Đồng" Ngọc Lũ nhé!

Các bạn hãy nhìn vào chính giữa mặt trống này, đó là một ngôi sao 14 cánh sáng chói như Mặt Trời mùa hè vậy. Xung quanh là đàn chim Lạc đang giang rộng đôi cánh bay lượn!

Đố các bạn biết trên mặt trống các bác người xưa đang làm gì? A, có bác đang giã gạo này, có bác đang gõ trống cắc tùng cắc tùng, và có cả những ngôi nhà sàn mái cong xinh xắn nữa đấy!`,
    changesSummary: 'Thêm kịch bản thuyết minh sinh động dành cho thiếu nhi (6–12 tuổi), được tạo trong xưởng nội dung AI và nhân viên hiệu chỉnh.',
    feedback: ''
  },
  {
    id: 'cur-002',
    type: 'quiz',
    title: 'Bộ câu hỏi tương tác: Thạp đồng Đào Thịnh (4 câu)',
    targetArtifactId: 'art-002',
    targetArtifactName: 'Thạp đồng Đào Thịnh',
    submittedBy: 'Lê Tuấn Kiệt (Nhân viên bảo tàng)',
    submittedDate: '2026-09-27 11:15',
    status: 'pending',
    priority: 'medium',
    currentVersion: 'Chưa có bộ câu hỏi tương tác trên hệ thống',
    proposedContent: JSON.stringify([
      {
        question: 'Thạp đồng Đào Thịnh được phát hiện tại tỉnh nào của nước ta?',
        options: ['Yên Bái', 'Thanh Hóa', 'Phú Thọ', 'Hòa Bình'],
        correctIndex: 0,
        explanation: 'Thạp đồng Đào Thịnh được tình cờ phát hiện năm 1961 tại bờ sông Hồng thuộc tỉnh Yên Bái.'
      },
      {
        question: 'Hình tượng nào trên nắp thạp thể hiện ước vọng sinh sôi nảy nở của người Việt cổ?',
        options: ['4 tượng tròn đôi nam nữ', 'Hình tượng cá sấu săn mồi', 'Hình đàn chim Lạc', 'Hình hoa văn răng cưa'],
        correctIndex: 0,
        explanation: 'Khối tượng tròn nam nữ giao phối trên nắp thạp là biểu tượng phồn thực rõ nét nhất của văn hóa Đông Sơn.'
      }
    ], null, 2),
    changesSummary: 'Thêm 2 câu hỏi trắc nghiệm mới vào kho câu hỏi hiện vật để tăng điểm thưởng cho khách tham quan.',
    feedback: ''
  },
  {
    id: 'cur-003',
    type: 'artifact_update',
    title: 'Cập nhật niên đại & bản dịch tiếng Anh: Tượng Phật Bà Quan Âm',
    targetArtifactId: 'art-003',
    targetArtifactName: 'Tượng Phật Bà Quan Âm Nghìn Mắt Nghìn Tay',
    submittedBy: 'Nguyễn Mai Anh (Nhân viên bảo tàng)',
    submittedDate: '2026-09-26 16:40',
    status: 'pending',
    priority: 'low',
    currentVersion: 'Niên đại ghi: Thế kỷ XVII',
    proposedContent: 'Cập nhật chính xác năm hoàn thành tác phẩm là Năm Bính Thân (1656) theo minh văn trên tượng do Trương Thọ Nam tạc, đồng thời bổ sung thông tin 42 tay lớn và 952 tay nhỏ.',
    changesSummary: 'Hiệu đính số liệu chi tiết về số lượng cánh tay và năm tạc chính xác theo hồ sơ Bảo vật Quốc gia mới nhất.',
    feedback: ''
  }
];

export const initialUsers = [
  {
    id: 'usr-001',
    name: 'Vũ Hải Đăng',
    email: 'admin@smgs.vn',
    role: 'administrator', // administrator | museumStaff | systemStaff | visitor
    museumId: 'all',
    museumName: 'Toàn hệ thống',
    phone: '0912 345 678',
    status: 'active',
    lastLogin: '2026-09-27 21:10',
    permissions: ['all_access', 'user_management', 'finance_audit', 'system_config']
  },
  {
    id: 'usr-002',
    name: 'Trần Minh Châu',
    email: 'system@smgs.vn',
    role: 'systemStaff',
    museumId: 'all',
    museumName: 'Toàn hệ thống',
    phone: '0988 765 432',
    status: 'active',
    lastLogin: '2026-09-27 19:45',
    permissions: ['visitor_support', 'complaints', 'refund_requests', 'transaction_reconciliation', 'moderate_reviews', 'monitor_operations', 'monitor_ai_quality']
  },
  {
    id: 'usr-003',
    name: 'Lê Bích Ngọc',
    email: 'system2@smgs.vn',
    role: 'systemStaff',
    museumId: 'all',
    museumName: 'Toàn hệ thống',
    phone: '0977 123 987',
    status: 'active',
    lastLogin: '2026-09-27 15:20',
    permissions: ['visitor_support', 'complaints', 'moderate_reviews', 'monitor_operations', 'monitor_ai_quality']
  },
  {
    id: 'usr-004',
    name: 'Nguyễn Mai Anh',
    email: 'staff@smgs.vn',
    role: 'museumStaff',
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia (Tòa nhà A)',
    assignedGalleries: ['Phòng Văn hóa Đông Sơn', 'Phòng Sa Huỳnh'],
    phone: '0904 555 123',
    status: 'active',
    lastLogin: '2026-09-27 20:30',
    permissions: ['manage_museum', 'manage_artifacts', 'manage_media', 'manage_qr', 'edit_tours', 'create_ai_content', 'approve_publish', 'configure_premium', 'view_museum_reports']
  },
  {
    id: 'usr-005',
    name: 'Lê Tuấn Kiệt',
    email: 'staff2@smgs.vn',
    role: 'museumStaff',
    museumId: 'mus-01',
    museumName: 'Bảo tàng Lịch sử Quốc gia (Tòa nhà B)',
    assignedGalleries: ['Phòng Cận Hiện đại'],
    phone: '0918 888 777',
    status: 'active',
    lastLogin: '2026-09-27 17:00',
    permissions: ['manage_artifacts', 'create_ai_content', 'submit_curation']
  },
  {
    id: 'usr-006',
    name: 'Trần Ngọc Ánh',
    email: 'tran.ngoc.anh@gmail.com',
    role: 'visitor',
    museumId: null,
    museumName: 'Ứng dụng di động',
    phone: '0902 123 456',
    status: 'active',
    lastLogin: '2026-10-05 08:30',
    permissions: ['browse_museums', 'scan_artifacts', 'purchase_pass']
  }
];

export const initialPassPackages = [
  {
    id: 'pkg-01',
    name: 'Gói Hướng dẫn số Tiêu chuẩn',
    durationDays: 1,
    price: 29000,
    features: ['Nghe thuyết minh đa ngôn ngữ cho mọi hiện vật', 'Quét mã QR không giới hạn', 'Trả lời câu hỏi nhận huy hiệu di sản'],
    activePassesCount: 840,
    status: 'active'
  },
  {
    id: 'pkg-02',
    name: 'Gói Hành trình di sản nâng cao',
    durationDays: 3,
    price: 59000,
    features: ['Toàn bộ quyền lợi gói Tiêu chuẩn', 'Hỏi đáp với hướng dẫn viên AI không giới hạn', 'Tạo hành trình theo sở thích và thời gian', 'Xem mô hình 3D tương tác'],
    activePassesCount: 1420,
    status: 'active'
  },
  {
    id: 'pkg-03',
    name: 'Gói Gia đình và Nhóm',
    durationDays: 7,
    price: 119000,
    features: ['Dành cho nhóm tối đa 5 thiết bị', 'Thuyết minh riêng cho thiếu nhi và người lớn', 'Bộ câu hỏi dành cho gia đình', 'Lưu nhật ký tham quan và kỷ yếu số'],
    activePassesCount: 310,
    status: 'active'
  }
];

export const initialTransactions = [
  {
    id: 'TXN-98421',
    userEmail: 'tran.ngoc.anh@gmail.com',
    userName: 'Trần Ngọc Ánh',
    packageName: 'Gói Hành trình di sản nâng cao',
    amount: 59000,
    method: 'VNPay QR',
    status: 'completed', // completed | pending | refunded
    timestamp: '2026-09-27 21:05',
    museumCode: 'VNMH'
  },
  {
    id: 'TXN-98420',
    userEmail: 'le.minh.hoang@yahoo.com',
    userName: 'Lê Minh Hoàng',
    packageName: 'Gói Hướng dẫn số Tiêu chuẩn',
    amount: 29000,
    method: 'MoMo',
    status: 'completed',
    timestamp: '2026-09-27 20:48',
    museumCode: 'VNMH'
  },
  {
    id: 'TXN-98419',
    userEmail: 'john.smith92@hotmail.com',
    userName: 'John Smith',
    packageName: 'Gói Hành trình di sản nâng cao',
    amount: 59000,
    method: 'Visa / Mastercard',
    status: 'completed',
    timestamp: '2026-09-27 20:12',
    museumCode: 'VNMH'
  },
  {
    id: 'TXN-98418',
    userEmail: 'nguyen.van.hung@gmail.com',
    userName: 'Nguyễn Văn Hùng',
    packageName: 'Gói Gia đình và Nhóm',
    amount: 119000,
    method: 'ZaloPay',
    status: 'refunded',
    timestamp: '2026-09-27 18:30',
    museumCode: 'VNMH'
  },
  {
    id: 'TXN-98417',
    userEmail: 'dao.thi.thao@outlook.com',
    userName: 'Đào Thị Thảo',
    packageName: 'Gói Hướng dẫn số Tiêu chuẩn',
    amount: 29000,
    method: 'VNPay QR',
    status: 'completed',
    timestamp: '2026-09-27 17:55',
    museumCode: 'HCM-MUS'
  }
];

export const initialReviews = [
  {
    id: 'rev-001',
    visitorName: 'Đoàn Gia Bảo',
    visitorEmail: 'giabao.doan@gmail.com',
    artifactId: 'art-001',
    artifactName: 'Trống đồng Ngọc Lũ',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    rating: 5,
    date: '2026-09-27 19:15',
    comment: 'Mô hình 3D xoay mượt mà, AI giải thích các vành hoa văn chim Lạc rất dễ hiểu và chi tiết. Các bé nhà mình thích mê!',
    officialReply: 'Bảo tàng trân trọng cảm ơn phản hồi của anh Bảo và gia đình. Chúc gia đình có thêm nhiều trải nghiệm ý nghĩa tại bảo tàng!',
    replyDate: '2026-09-27 20:00',
    status: 'replied'
  },
  {
    id: 'rev-002',
    visitorName: 'Emily Watson',
    visitorEmail: 'emily.w@traveler.org',
    artifactId: 'art-002',
    artifactName: 'Thạp đồng Đào Thịnh',
    museumName: 'Bảo tàng Lịch sử Quốc gia',
    rating: 5,
    date: '2026-09-27 16:40',
    comment: 'The English audio narration is top quality and voice pacing is wonderful. Great technology for international tourists.',
    officialReply: '',
    replyDate: '',
    status: 'pending_reply'
  },
  {
    id: 'rev-003',
    visitorName: 'Vũ Quốc Khánh',
    visitorEmail: 'khanh.vq@fpt.edu.vn',
    artifactId: 'art-003',
    artifactName: 'Tượng Phật Quan Âm',
    museumName: 'Bảo tàng Mỹ thuật Việt Nam',
    rating: 4,
    date: '2026-09-26 14:10',
    comment: 'Tượng rất uy nghiêm, đề xuất bổ sung thêm phần zoom cận cảnh chi tiết bàn tay và mắt trong lòng bàn tay trên bản đồ 3D.',
    officialReply: 'Cảm ơn bạn Khánh đã góp ý. Đội ngũ kỹ thuật bảo tàng đang số hóa 3D độ phân giải siêu cao cho pho tượng này trong quý tới.',
    replyDate: '2026-09-26 15:30',
    status: 'replied'
  }
];

export const initialSystemCases = [
  { id: 'YC-101', type: 'support', title: 'Không mở được hướng dẫn số', visitor: 'Trần Ngọc Ánh', museum: 'Bảo tàng Lịch sử Quốc gia', detail: 'Ứng dụng báo vé chưa kích hoạt sau khi thanh toán.', status: 'new', priority: 'high', createdAt: '2026-10-05 09:20' },
  { id: 'YC-102', type: 'complaint', title: 'Nội dung thuyết minh chưa chính xác', visitor: 'Lê Minh Hoàng', museum: 'Bảo tàng Lịch sử Quốc gia', detail: 'Khách yêu cầu kiểm tra niên đại hiển thị ở trang hiện vật.', status: 'in_progress', priority: 'medium', createdAt: '2026-10-05 08:45' },
  { id: 'YC-103', type: 'refund', title: 'Yêu cầu hoàn tiền gói hướng dẫn số', visitor: 'Trần Ngọc Ánh', museum: 'Bảo tàng Lịch sử Quốc gia', transactionId: 'TXN-98421', detail: 'Khách báo không sử dụng được gói sau khi mua.', status: 'new', priority: 'high', createdAt: '2026-10-05 09:05' },
  { id: 'YC-104', type: 'operations', title: 'Mã QR tại phòng trưng bày không mở', visitor: 'Đội vận hành', museum: 'Bảo tàng Lịch sử Quốc gia', detail: 'Theo dõi lỗi đọc mã QR tại khu Đông Sơn.', status: 'in_progress', priority: 'high', createdAt: '2026-10-05 07:30' },
  { id: 'YC-105', type: 'ai_quality', title: 'AI trả lời thiếu nguồn tham khảo', visitor: 'Đội chất lượng AI', museum: 'Bảo tàng Mỹ thuật Việt Nam', detail: 'Kiểm tra câu trả lời về Tượng Phật Quan Âm trước khi chuyển cho bảo tàng hiệu đính.', status: 'new', priority: 'medium', createdAt: '2026-10-05 08:10' }
];

export const initialAuditLogs = [
  {
    id: 'log-101',
    timestamp: '2026-09-27 21:05',
    user: 'Vũ Hải Đăng (admin@smgs.vn)',
    role: 'Quản trị viên',
    action: 'SYSTEM_SETTINGS_UPDATE',
    details: 'Cập nhật API Key Gemini 2.0 Flash cho tính năng AI Content Studio.'
  },
  {
    id: 'log-100',
    timestamp: '2026-09-27 20:30',
    user: 'Nguyễn Mai Anh (staff@smgs.vn)',
    role: 'Nhân viên bảo tàng',
    action: 'AI_CONTENT_GENERATE',
    details: 'Tạo bản thuyết minh AI Thiếu nhi cho Trống đồng Ngọc Lũ và gửi kiểm duyệt.'
  },
  {
    id: 'log-099',
    timestamp: '2026-09-27 19:45',
    user: 'Nguyễn Mai Anh (staff@smgs.vn)',
    role: 'Nhân viên bảo tàng',
    action: 'CURATION_APPROVE',
    details: 'Phê duyệt xuất bản bài thuyết minh nâng cao cho hiện vật Trống đồng Cảnh Thịnh.'
  },
  {
    id: 'log-098',
    timestamp: '2026-09-27 17:15',
    user: 'Lê Tuấn Kiệt (staff2@smgs.vn)',
    role: 'Nhân viên bảo tàng',
    action: 'ARTIFACT_CREATE',
    details: 'Đăng tải thông tin & mã QR mẫu cho hiện vật mới: Bình gốm hoa nâu thời Lý.'
  },
  {
    id: 'log-097',
    timestamp: '2026-09-27 15:00',
    user: 'Vũ Hải Đăng (admin@smgs.vn)',
    role: 'Quản trị viên',
    action: 'USER_ROLE_ASSIGN',
    details: 'Phân quyền Nhân viên hệ thống cho Lê Bích Ngọc.'
  }
];
