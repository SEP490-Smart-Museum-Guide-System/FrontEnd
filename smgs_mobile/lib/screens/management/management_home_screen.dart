import 'package:flutter/material.dart';

import '../../models/experience.dart';
import '../../services/app_services.dart';
import '../../widgets/museum_ui.dart';

class ManagementHomeScreen extends StatelessWidget {
  const ManagementHomeScreen({super.key, required this.role});

  final UserRole role;

  bool get _isAdmin => role == UserRole.administrator;

  @override
  Widget build(BuildContext context) {
    final user = AppServices.auth.user!;
    final actions = _isAdmin ? _adminActions : _curatorActions;
    return Scaffold(
      body: MuseumPage(
        eyebrow: _isAdmin ? 'Không gian quản trị' : 'Không gian nghiệp vụ',
        title: _isAdmin ? 'Điều hành\nhệ thống.' : 'Chăm sóc\ndi sản số.',
        subtitle: _isAdmin
            ? 'Theo dõi vận hành, con người và quyền truy cập SMGS.'
            : 'Kiểm duyệt nội dung trước khi câu chuyện đến với khách tham quan.',
        children: [
          _RoleHero(
            icon: _isAdmin
                ? Icons.admin_panel_settings_outlined
                : Icons.workspace_premium_outlined,
            roleName: _isAdmin
                ? 'Quản trị viên'
                : 'Nhân viên / Kiểm duyệt viên',
            name: user.name,
            email: user.email,
          ),
          const SectionHeading('Tổng quan hôm nay'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: (_isAdmin ? _adminMetrics : _curatorMetrics)
                .map((metric) => _MetricCard(metric: metric))
                .toList(),
          ),
          SectionHeading(
            _isAdmin ? 'Điều hành hệ thống' : 'Công việc nội dung',
          ),
          ...actions.map(
            (action) => ActionTile(
              title: action.title,
              subtitle: action.subtitle,
              icon: action.icon,
              onTap: () => _openFeature(context, action),
            ),
          ),
          const SizedBox(height: 14),
          SecondaryButton(
            label: 'Đăng xuất',
            icon: Icons.logout,
            onPressed: AppServices.auth.logout,
          ),
          const SizedBox(height: 14),
          const Notice(
            'Đây là dữ liệu mô phỏng để xem luồng và giao diện theo vai trò.',
          ),
        ],
      ),
    );
  }

  void _openFeature(BuildContext context, _ManagementAction action) {
    showReading(
      context,
      title: action.title,
      text:
          '${action.detail}\n\n'
          'Màn hình mẫu đã phản ánh phạm vi nghiệp vụ trong sơ đồ use case. '
          'Dữ liệu thật sẽ được nối qua API của hệ thống.',
    );
  }
}

class _RoleHero extends StatelessWidget {
  const _RoleHero({
    required this.icon,
    required this.roleName,
    required this.name,
    required this.email,
  });

  final IconData icon;
  final String roleName, name, email;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.deepBurgundy,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.antiqueIvory.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: AppColors.mutedGold, size: 30),
            ),
            const Spacer(),
            const HeritageSeal(size: 42, light: true),
          ],
        ),
        const SizedBox(height: 20),
        Eyebrow(roleName, light: true),
        const SizedBox(height: 8),
        Text(
          name,
          style: AppTextStyles.cardTitle.copyWith(color: AppColors.lightText),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.antiqueIvory.withValues(alpha: .82),
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _ManagementMetric metric;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 134,
    child: Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, size: 22, color: AppColors.mutedGold),
          const SizedBox(height: 10),
          Text(metric.value, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 2),
          Text(metric.label, style: AppTextStyles.caption),
        ],
      ),
    ),
  );
}

class _ManagementMetric {
  const _ManagementMetric(this.value, this.label, this.icon);
  final String value, label;
  final IconData icon;
}

class _ManagementAction {
  const _ManagementAction(this.title, this.subtitle, this.detail, this.icon);
  final String title, subtitle, detail;
  final IconData icon;
}

const _curatorMetrics = [
  _ManagementMetric('12', 'Chờ duyệt', Icons.pending_actions_outlined),
  _ManagementMetric('38', 'Đã xuất bản', Icons.task_alt_outlined),
  _ManagementMetric('4,8', 'Đánh giá', Icons.star_outline),
];

const _adminMetrics = [
  _ManagementMetric('1.284', 'Người dùng', Icons.group_outlined),
  _ManagementMetric('06', 'Bảo tàng', Icons.account_balance_outlined),
  _ManagementMetric('98%', 'Ổn định', Icons.monitor_heart_outlined),
];

const _curatorActions = [
  _ManagementAction(
    'Quản lý nội dung bảo tàng',
    'Hiện vật, hình ảnh, thư viện và bản đồ.',
    'Tạo mới, chỉnh sửa thông tin hiện vật; quản lý phương tiện và sơ đồ trưng bày.',
    Icons.museum_outlined,
  ),
  _ManagementAction(
    'Tạo nội dung bằng AI',
    'Soạn thuyết minh và câu hỏi thử tài.',
    'Khởi tạo bản nháp thuyết minh và bộ câu hỏi từ dữ liệu hiện vật đã xác thực.',
    Icons.auto_awesome_outlined,
  ),
  _ManagementAction(
    'Kiểm duyệt nội dung',
    '12 bản nháp đang chờ xử lý.',
    'Đọc, chỉnh sửa, phê duyệt hoặc từ chối nội dung trước khi xuất bản.',
    Icons.fact_check_outlined,
  ),
  _ManagementAction(
    'Xuất bản',
    'Đưa nội dung đã duyệt đến khách tham quan.',
    'Kiểm tra phiên bản cuối và lên lịch xuất bản nội dung.',
    Icons.publish_outlined,
  ),
  _ManagementAction(
    'Phản hồi và báo cáo',
    'Theo dõi cảm nhận của khách tham quan.',
    'Tổng hợp đánh giá theo bảo tàng, hiện vật và hành trình.',
    Icons.insights_outlined,
  ),
];

const _adminActions = [
  _ManagementAction(
    'Quản lý người dùng',
    'Tài khoản, trạng thái và hoạt động.',
    'Tìm kiếm tài khoản, khóa hoặc mở quyền truy cập khi cần.',
    Icons.manage_accounts_outlined,
  ),
  _ManagementAction(
    'Vai trò và phân quyền',
    'Thiết lập quyền theo trách nhiệm.',
    'Quản lý vai trò và phạm vi thao tác của từng nhóm tài khoản.',
    Icons.security_outlined,
  ),
  _ManagementAction(
    'Quản lý bảo tàng',
    'Hồ sơ bảo tàng và phân công nhân sự.',
    'Cập nhật đơn vị, trạng thái hoạt động và gán nhân viên phụ trách.',
    Icons.account_balance_outlined,
  ),
  _ManagementAction(
    'Theo dõi giao dịch',
    'Thanh toán và kích hoạt dịch vụ số.',
    'Đối soát giao dịch, trạng thái thanh toán và quyền lợi đã kích hoạt.',
    Icons.receipt_long_outlined,
  ),
  _ManagementAction(
    'Nhật ký hệ thống',
    'Tra cứu các thay đổi quan trọng.',
    'Theo dõi người thực hiện, thời điểm và nội dung thay đổi.',
    Icons.history_outlined,
  ),
  _ManagementAction(
    'Cài đặt hệ thống',
    'Cấu hình vận hành chung của SMGS.',
    'Quản lý thông số hệ thống và chính sách trải nghiệm.',
    Icons.settings_outlined,
  ),
];
