import 'package:flutter/material.dart';
import 'museum_ui.dart';

class BackendPanel extends StatefulWidget {
  const BackendPanel({
    super.key,
    required this.resourceKey,
    required this.load,
    required this.builder,
  });
  final String resourceKey;
  final Future<dynamic> Function() load;
  final Widget Function(dynamic data, VoidCallback reload) builder;
  @override
  State<BackendPanel> createState() => _BackendPanelState();
}

class _BackendPanelState extends State<BackendPanel> {
  late Future<dynamic> _future = widget.load();
  void _reload() {
    if (mounted) setState(() => _future = widget.load());
  }

  @override
  void didUpdateWidget(covariant BackendPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resourceKey != widget.resourceKey) _future = widget.load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Column(
          children: [
            Notice(snapshot.error.toString()),
            TextButton(onPressed: _reload, child: const Text('Thử lại')),
          ],
        );
      }
      return widget.builder(snapshot.data, _reload);
    },
  );
}

String backendStatus(dynamic value) =>
    const {
      'draft': 'Bản nháp',
      'pending': 'Chờ xử lý',
      'paid': 'Đã thanh toán',
      'succeeded': 'Thành công',
      'failed': 'Thất bại',
      'in_progress': 'Đang thực hiện',
      'completed': 'Hoàn thành',
      'abandoned': 'Đã dừng',
      'InProgress': 'Đang thực hiện',
      'Completed': 'Đã hoàn thành',
      'Open': 'Mới tiếp nhận',
      'Resolved': 'Đã giải quyết',
      'Visible': 'Hiển thị',
      'Hidden': 'Đã ẩn',
    }[value] ??
    value?.toString() ??
    'Chưa có dữ liệu';
