import 'package:flutter/material.dart';

import '../../models/experience.dart';
import '../../services/app_services.dart';
import '../../widgets/museum_ui.dart';

class ManagementHomeScreen extends StatefulWidget {
  const ManagementHomeScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<ManagementHomeScreen> createState() => _ManagementHomeScreenState();
}

class _ManagementHomeScreenState extends State<ManagementHomeScreen> {
  int _selectedIndex = 0;

  bool get _isAdmin => widget.role == UserRole.administrator;
  List<_NavItem> get _items => _isAdmin ? _adminItems : _curatorItems;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _isAdmin
        ? const Color(0xFFF3F5F7)
        : const Color(0xFFF6EFE4),
    body: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) return _buildCompact(context);
        return Row(
          children: [
            _Sidebar(
              isAdmin: _isAdmin,
              items: _items,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(isAdmin: _isAdmin),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 30, 32, 48),
                      child: _buildPage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _buildCompact(BuildContext context) => Scaffold(
    backgroundColor: _isAdmin
        ? const Color(0xFFF3F5F7)
        : const Color(0xFFF6EFE4),
    appBar: AppBar(title: Text(_isAdmin ? 'Quản trị SMGS' : 'Nghiệp vụ SMGS')),
    drawer: Drawer(
      child: _Sidebar(
        isAdmin: _isAdmin,
        items: _items,
        selectedIndex: _selectedIndex,
        compact: true,
        onSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: _buildPage(),
    ),
  );

  Widget _buildPage() => _selectedIndex == 0
      ? (_isAdmin ? const _OverviewPage(isAdmin: true) : const _CuratorStudio())
      : _WorkspacePage(item: _items[_selectedIndex], isAdmin: _isAdmin);
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.isAdmin,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
  });

  final bool isAdmin, compact;
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? double.infinity : 276,
    color: isAdmin ? const Color(0xFF252B33) : AppColors.deepBurgundy,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 20, 24),
            child: Row(
              children: [
                const HeritageSeal(size: 42, light: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMGS',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.lightText,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        isAdmin ? 'Cổng quản trị' : 'Cổng nghiệp vụ',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.antiqueIvory.withValues(alpha: .72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.antiqueIvory.withValues(alpha: .14)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Material(
                    color: selected
                        ? AppColors.antiqueIvory.withValues(alpha: .13)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(7),
                      onTap: () => onSelected(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 21,
                              color: selected
                                  ? AppColors.mutedGold
                                  : AppColors.antiqueIvory.withValues(
                                      alpha: .76,
                                    ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(
                                item.label,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.lightText,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (item.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mutedGold,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.badge!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.darkBrown,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.antiqueIvory,
                side: BorderSide(
                  color: AppColors.antiqueIvory.withValues(alpha: .35),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: AppServices.auth.logout,
              icon: const Icon(Icons.logout, size: 19),
              label: const Text('Đăng xuất'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final user = AppServices.auth.user!;
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFFDFEFE) : const Color(0xFFFFF9F0),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: isAdmin
                    ? 'Tìm người dùng, giao dịch, bảo tàng…'
                    : 'Tìm hiện vật, bản nháp, chuyên đề…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: isAdmin
                    ? const Color(0xFFF0F2F4)
                    : const Color(0xFFF3EDE4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () {},
            icon: const Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_none_outlined),
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 32, color: AppColors.border),
          const SizedBox(width: 18),
          CircleAvatar(
            backgroundColor: isAdmin
                ? const Color(0xFF252B33)
                : AppColors.deepBurgundy,
            foregroundColor: AppColors.lightText,
            child: Text(isAdmin ? 'QT' : 'NV'),
          ),
          const SizedBox(width: 11),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                ),
              ),
              Text(
                isAdmin ? 'Quản trị viên' : 'Nhân viên kiểm duyệt',
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CuratorStudio extends StatelessWidget {
  const _CuratorStudio();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.deepBurgundy,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Bàn biên tập hôm nay', light: true),
                  const SizedBox(height: 10),
                  Text(
                    'Kể câu chuyện\ndi sản thật hay.',
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.lightText,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '12 nội dung đang chờ bạn kiểm duyệt trước khi xuất bản.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.antiqueIvory.withValues(alpha: .8),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mutedGold,
                      foregroundColor: AppColors.darkBrown,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.edit_note_outlined),
                    label: const Text('Mở hàng chờ kiểm duyệt'),
                  ),
                ],
              ),
            ),
            if (MediaQuery.sizeOf(context).width >= 600) ...[
              const SizedBox(width: 24),
              const HeritageSeal(size: 112, light: true),
            ],
          ],
        ),
      ),
      const SizedBox(height: 26),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 4,
        children: [
          Text('Dòng chảy nội dung', style: AppTextStyles.sectionTitle),
          Text('48 nội dung trong tháng 9', style: AppTextStyles.caption),
        ],
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 520
              ? 2
              : 1;
          final width = (constraints.maxWidth - (count - 1) * 12) / count;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _StageCard('18', 'Bản nháp', Icons.description_outlined),
              _StageCard('09', 'AI đang hỗ trợ', Icons.auto_awesome_outlined),
              _StageCard('12', 'Chờ kiểm duyệt', Icons.fact_check_outlined),
              _StageCard('07', 'Sẵn sàng xuất bản', Icons.publish_outlined),
            ].map((card) => SizedBox(width: width, child: card)).toList(),
          );
        },
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, constraints) {
          final preview = const _FeaturedDraft();
          final queue = const _EditorialQueue();
          return constraints.maxWidth >= 980
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _FeaturedDraft()),
                    SizedBox(width: 20),
                    Expanded(flex: 4, child: _EditorialQueue()),
                  ],
                )
              : Column(children: [preview, const SizedBox(height: 20), queue]);
        },
      ),
    ],
  );
}

class _StageCard extends StatelessWidget {
  const _StageCard(this.value, this.label, this.icon);
  final String value, label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFAF2),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.deepBurgundy, size: 25),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.sectionTitle),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ],
    ),
  );
}

class _FeaturedDraft extends StatelessWidget {
  const _FeaturedDraft();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFFAF2),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MuseumPhoto(museumId: 'museum_national', height: 210),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Bản nháp nổi bật'),
              const SizedBox(height: 9),
              Text(
                'Tiếng vọng từ trống đồng Ngọc Lũ',
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'Bản thuyết minh AI đã được đối chiếu nguồn và đang chờ biên tập câu chữ cuối.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.mutedGold,
                    child: Text('TH'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lê Thu Hà · sửa 18 phút trước',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Mở bản nháp'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EditorialQueue extends StatelessWidget {
  const _EditorialQueue();

  @override
  Widget build(BuildContext context) => _WebPanel(
    title: 'Tiếp theo trong hàng chờ',
    action: 'Xem tất cả',
    child: Column(
      children: const [
        _QueueItem(
          'Áo Nhật Bình triều Nguyễn',
          'Bộ câu hỏi · 8 câu',
          'Ưu tiên',
        ),
        _QueueItem(
          'Gốm hoa lam thế kỷ XV',
          'Thuyết minh · 04:20 phút',
          'Chờ duyệt',
        ),
        _QueueItem('Bản đồ tầng 2', 'Lộ trình · 6 điểm dừng', 'Cần sửa'),
        _QueueItem(
          'Ký ức mùa thu Hà Nội',
          'Chuyên đề · 12 hiện vật',
          'Bản nháp',
        ),
      ],
    ),
  );
}

class _QueueItem extends StatelessWidget {
  const _QueueItem(this.title, this.subtitle, this.status);
  final String title, subtitle, status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Container(
          width: 7,
          height: 42,
          decoration: BoxDecoration(
            color: status == 'Ưu tiên'
                ? AppColors.deepBurgundy
                : AppColors.mutedGold,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
        Text(status, style: AppTextStyles.caption),
      ],
    ),
  );
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final metrics = isAdmin ? _adminMetrics : _curatorMetrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Thứ sáu, 18 tháng 9'),
                  const SizedBox(height: 7),
                  Text(
                    isAdmin ? 'Tổng quan hệ thống' : 'Bàn làm việc nội dung',
                    style: AppTextStyles.display.copyWith(fontSize: 34),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    isAdmin
                        ? 'Theo dõi vận hành và quản lý quyền truy cập tại một nơi.'
                        : 'Những nội dung cần bạn xem xét trước khi xuất bản.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: Icon(isAdmin ? Icons.person_add_alt : Icons.add),
              label: Text(isAdmin ? 'Thêm người dùng' : 'Tạo nội dung'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 620
                ? 2
                : 1;
            final width = (constraints.maxWidth - (count - 1) * 14) / count;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: metrics
                  .map(
                    (metric) =>
                        SizedBox(width: width, child: _MetricCard(metric)),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final primary = _PriorityPanel(isAdmin: isAdmin);
            final secondary = _ActivityPanel(isAdmin: isAdmin);
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: primary),
                      const SizedBox(width: 20),
                      Expanded(flex: 3, child: secondary),
                    ],
                  )
                : Column(
                    children: [primary, const SizedBox(height: 20), secondary],
                  );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.metric);
  final _Metric metric;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFCFAF6),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.antiqueIvory,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(metric.icon, color: AppColors.deepBurgundy),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.value, style: AppTextStyles.sectionTitle),
              Text(metric.label, style: AppTextStyles.caption),
            ],
          ),
        ),
        Text(
          metric.trend,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF2F765B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _PriorityPanel extends StatelessWidget {
  const _PriorityPanel({required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final rows = isAdmin ? _adminPriority : _curatorPriority;
    return _WebPanel(
      title: isAdmin ? 'Cần chú ý' : 'Hàng chờ kiểm duyệt',
      action: 'Xem tất cả',
      child: Column(
        children: rows
            .map(
              (row) => Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: row.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(row.icon, color: row.color, size: 21),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(row.subtitle, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: row.color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        row.status,
                        style: AppTextStyles.caption.copyWith(
                          color: row.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context) => _WebPanel(
    title: isAdmin ? 'Hoạt động gần đây' : 'Tiến độ xuất bản',
    child: Column(
      children: [
        if (!isAdmin) ...[
          const _ProgressLine('Đã kiểm duyệt', 38, 48),
          const _ProgressLine('Đã xuất bản', 31, 48),
          const _ProgressLine('Cần chỉnh sửa', 7, 48),
          const SizedBox(height: 12),
        ],
        ...[
          (
            '10:42',
            isAdmin
                ? 'Cập nhật quyền nhóm Biên tập'
                : 'Đã duyệt Trống đồng Ngọc Lũ',
          ),
          (
            '09:18',
            isAdmin
                ? 'Phân công 2 nhân viên mới'
                : 'Đã chỉnh sửa thuyết minh AI',
          ),
          (
            'Hôm qua',
            isAdmin ? 'Đối soát 24 giao dịch' : 'Đã xuất bản 5 hiện vật',
          ),
        ].map(
          (activity) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.mutedGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(activity.$2, style: AppTextStyles.caption),
                ),
                Text(activity.$1, style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine(this.label, this.value, this.total);
  final String label;
  final int value, total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.caption)),
            Text('$value/$total', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: value / total, minHeight: 7),
      ],
    ),
  );
}

class _WorkspacePage extends StatelessWidget {
  const _WorkspacePage({required this.item, required this.isAdmin});
  final _NavItem item;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) return _CuratorWorkspace(item: item);
    final rows = _workspaceRows(item.label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('SMGS · Không gian làm việc'),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: AppTextStyles.display),
                  const SizedBox(height: 6),
                  Text(item.description, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: Text(isAdmin ? 'Thêm mới' : 'Tạo bản nháp'),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _WebPanel(
          title: 'Danh sách làm việc',
          action: 'Bộ lọc',
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: _TableLabel('NỘI DUNG')),
                    Expanded(flex: 2, child: _TableLabel('PHỤ TRÁCH')),
                    Expanded(flex: 2, child: _TableLabel('CẬP NHẬT')),
                    Expanded(flex: 2, child: _TableLabel('TRẠNG THÁI')),
                    SizedBox(width: 34),
                  ],
                ),
              ),
              ...rows.map(
                (row) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          row.$1,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(row.$2, style: AppTextStyles.caption),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(row.$3, style: AppTextStyles.caption),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.antiqueIvory,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              row.$4,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 34,
                        child: Icon(Icons.more_horiz, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CuratorWorkspace extends StatelessWidget {
  const _CuratorWorkspace({required this.item});
  final _NavItem item;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Eyebrow('Xưởng nội dung · SMGS'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: AppTextStyles.display),
                const SizedBox(height: 6),
                Text(item.description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Tạo bản nháp'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ChoiceChip(
            label: const Text('Tất cả 24'),
            selected: true,
            onSelected: (_) {},
          ),
          ChoiceChip(
            label: const Text('Bản nháp 8'),
            selected: false,
            onSelected: (_) {},
          ),
          ChoiceChip(
            label: const Text('Chờ duyệt 12'),
            selected: false,
            onSelected: (_) {},
          ),
          ChoiceChip(
            label: const Text('Cần sửa 4'),
            selected: false,
            onSelected: (_) {},
          ),
        ],
      ),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 1050
              ? 3
              : constraints.maxWidth >= 640
              ? 2
              : 1;
          final width = (constraints.maxWidth - (count - 1) * 16) / count;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _curatorDrafts
                .map(
                  (draft) => SizedBox(
                    width: width,
                    child: _DraftCard(draft: draft),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});
  final _Draft draft;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFFAF2),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Padding(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.antiqueIvory,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(draft.icon, color: AppColors.deepBurgundy),
              ),
              const Spacer(),
              Text(draft.status, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 20),
          Text(draft.title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 7),
          Text(draft.subtitle, style: AppTextStyles.bodySmall),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Text(draft.updated, style: AppTextStyles.caption),
              ),
              IconButton(
                tooltip: 'Mở nội dung',
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 20),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TableLabel extends StatelessWidget {
  const _TableLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppTextStyles.caption.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: .8,
    ),
  );
}

class _WebPanel extends StatelessWidget {
  const _WebPanel({required this.title, required this.child, this.action});
  final String title;
  final String? action;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFCFAF6),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
            if (action != null)
              TextButton(onPressed: () {}, child: Text(action!)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.description, {this.badge});
  final String label, description;
  final IconData icon;
  final String? badge;
}

class _Metric {
  const _Metric(this.value, this.label, this.trend, this.icon);
  final String value, label, trend;
  final IconData icon;
}

class _PriorityRow {
  const _PriorityRow(
    this.title,
    this.subtitle,
    this.status,
    this.icon,
    this.color,
  );
  final String title, subtitle, status;
  final IconData icon;
  final Color color;
}

class _Draft {
  const _Draft(this.title, this.subtitle, this.status, this.updated, this.icon);
  final String title, subtitle, status, updated;
  final IconData icon;
}

const _curatorItems = [
  _NavItem(
    'Tổng quan',
    Icons.dashboard_outlined,
    'Tổng quan công việc trong ngày.',
  ),
  _NavItem(
    'Nội dung bảo tàng',
    Icons.museum_outlined,
    'Quản lý hiện vật, hình ảnh, thư viện và bản đồ.',
  ),
  _NavItem(
    'Nội dung AI',
    Icons.auto_awesome_outlined,
    'Tạo thuyết minh và câu hỏi thử tài bằng AI.',
  ),
  _NavItem(
    'Kiểm duyệt',
    Icons.fact_check_outlined,
    'Đọc, sửa, phê duyệt hoặc từ chối bản nháp.',
    badge: '12',
  ),
  _NavItem(
    'Xuất bản',
    Icons.publish_outlined,
    'Lên lịch và đưa nội dung đã duyệt đến khách tham quan.',
  ),
  _NavItem(
    'Phản hồi & báo cáo',
    Icons.insights_outlined,
    'Theo dõi đánh giá và báo cáo theo bảo tàng.',
  ),
];

const _adminItems = [
  _NavItem(
    'Tổng quan',
    Icons.dashboard_outlined,
    'Theo dõi tình trạng toàn hệ thống.',
  ),
  _NavItem(
    'Người dùng',
    Icons.manage_accounts_outlined,
    'Quản lý tài khoản và trạng thái truy cập.',
  ),
  _NavItem(
    'Vai trò & phân quyền',
    Icons.security_outlined,
    'Thiết lập quyền theo trách nhiệm.',
  ),
  _NavItem(
    'Bảo tàng & nhân sự',
    Icons.account_balance_outlined,
    'Quản lý đơn vị và phân công nhân viên.',
  ),
  _NavItem(
    'Giao dịch',
    Icons.receipt_long_outlined,
    'Theo dõi thanh toán và quyền dịch vụ.',
    badge: '3',
  ),
  _NavItem(
    'Nhật ký hệ thống',
    Icons.history_outlined,
    'Tra cứu các thay đổi quan trọng.',
  ),
  _NavItem(
    'Cài đặt',
    Icons.settings_outlined,
    'Cấu hình vận hành chung của SMGS.',
  ),
];

const _curatorMetrics = [
  _Metric('12', 'Chờ kiểm duyệt', '+3', Icons.pending_actions_outlined),
  _Metric('38', 'Đã duyệt tháng này', '+12%', Icons.task_alt_outlined),
  _Metric('07', 'Cần chỉnh sửa', '-2', Icons.edit_note_outlined),
  _Metric('4,8', 'Điểm đánh giá', '+0,2', Icons.star_outline),
];

const _adminMetrics = [
  _Metric('1.284', 'Người dùng', '+8,4%', Icons.group_outlined),
  _Metric('06', 'Bảo tàng hoạt động', '+1', Icons.account_balance_outlined),
  _Metric('126', 'Giao dịch hôm nay', '+14%', Icons.payments_outlined),
  _Metric('98,7%', 'Hệ thống ổn định', '+0,4%', Icons.monitor_heart_outlined),
];

const _curatorPriority = [
  _PriorityRow(
    'Trống đồng Ngọc Lũ',
    'Thuyết minh AI · Bảo tàng Lịch sử Quốc gia',
    'Chờ duyệt',
    Icons.graphic_eq,
    Color(0xFF9B6A32),
  ),
  _PriorityRow(
    'Áo Nhật Bình triều Nguyễn',
    'Bộ câu hỏi · Không gian Cung đình',
    'Cần sửa',
    Icons.quiz_outlined,
    Color(0xFF9A4545),
  ),
  _PriorityRow(
    'Bản đồ tầng 2',
    'Sơ đồ tham quan · Cập nhật lối đi',
    'Bản nháp',
    Icons.map_outlined,
    Color(0xFF527080),
  ),
];

const _adminPriority = [
  _PriorityRow(
    '03 giao dịch cần đối soát',
    'Cổng thanh toán MoMo · 18/09/2026',
    'Cần xử lý',
    Icons.receipt_long_outlined,
    Color(0xFF9A4545),
  ),
  _PriorityRow(
    'Yêu cầu cấp quyền mới',
    'Nguyễn Minh · Bảo tàng Hồ Chí Minh',
    'Chờ duyệt',
    Icons.person_add_alt,
    Color(0xFF9B6A32),
  ),
  _PriorityRow(
    'Đồng bộ bảo tàng hoàn tất',
    '06/06 đơn vị đang hoạt động',
    'Ổn định',
    Icons.cloud_done_outlined,
    Color(0xFF2F765B),
  ),
];

const _curatorDrafts = [
  _Draft(
    'Trống đồng Ngọc Lũ',
    'Thuyết minh âm thanh · Văn hóa Đông Sơn',
    'Chờ duyệt',
    'Sửa 18 phút trước',
    Icons.graphic_eq,
  ),
  _Draft(
    'Áo Nhật Bình',
    'Bộ câu hỏi thử tài · 8 câu',
    'Cần chỉnh sửa',
    'Sửa 1 giờ trước',
    Icons.quiz_outlined,
  ),
  _Draft(
    'Gốm hoa lam',
    'Thông tin hiện vật · 6 hình ảnh',
    'Bản nháp',
    'Sửa hôm qua',
    Icons.image_outlined,
  ),
  _Draft(
    'Dấu ấn cung đình',
    'Chuyên đề · 12 hiện vật',
    'Sẵn sàng',
    'Sửa hôm qua',
    Icons.collections_bookmark_outlined,
  ),
  _Draft(
    'Bản đồ tầng 2',
    'Sơ đồ bảo tàng · 6 điểm dừng',
    'Cần chỉnh sửa',
    'Sửa 16/09',
    Icons.map_outlined,
  ),
  _Draft(
    'Ký ức mùa thu Hà Nội',
    'Hành trình theo chủ đề · 45 phút',
    'Chờ duyệt',
    'Sửa 15/09',
    Icons.route_outlined,
  ),
];

List<(String, String, String, String)> _workspaceRows(String section) => [
  ('$section · Hồ sơ 01', 'Lê Thu Hà', '10 phút trước', 'Đang xử lý'),
  ('$section · Hồ sơ 02', 'Nguyễn Minh', 'Hôm nay', 'Chờ duyệt'),
  ('$section · Hồ sơ 03', 'Trần Anh', 'Hôm qua', 'Đã cập nhật'),
  ('$section · Hồ sơ 04', 'Hệ thống', '16/09/2026', 'Hoàn tất'),
];
