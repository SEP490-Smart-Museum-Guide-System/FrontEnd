import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, this.museumName});
  final String? museumName;
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Hiểu sâu hơn,\ntrải nghiệm trọn vẹn.',
    eyebrow: 'Dịch vụ số',
    subtitle: museumName ?? 'Những tiện ích đồng hành trong ngày tham quan.',
    children: [
      const Notice(
        'Dịch vụ số được cung cấp riêng, không bao gồm vé vào cửa bảo tàng.',
      ),
      const SizedBox(height: 24),
      for (final service in [
        (
          title: 'Hướng dẫn viên thông minh',
          description: 'Đặt câu hỏi và tìm hiểu thêm về câu chuyện phía sau từng hiện vật.',
          icon: Icons.chat_bubble_outline,
        ),
        (
          title: 'Thuyết minh trọn bộ',
          description:
              'Lắng nghe những câu chuyện được biên soạn cho chuyến tham quan.',
          icon: Icons.headphones_outlined,
        ),
        (
          title: 'Hành trình cá nhân',
          description: 'Khám phá theo thời gian và những chủ đề bạn yêu thích.',
          icon: Icons.route_outlined,
        ),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Panel(
            gold: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(service.icon, color: AppColors.deepBurgundy, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(child: Eyebrow('Đang chuẩn bị')),
                  ],
                ),
                const SizedBox(height: 18),
                Text(service.title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 12),
                Text(service.description, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 20),
                SecondaryButton(
                  label: 'Thông tin dịch vụ',
                  onPressed: () => showReading(
                    context,
                    title: service.title,
                    text:
                        '${service.description}\n\nDịch vụ dự kiến sử dụng theo ngày tại từng bảo tàng. Giá và ngày sử dụng sẽ được công bố khi mở bán.\n\nThanh toán chưa được kết nối trong bản trải nghiệm này.',
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
