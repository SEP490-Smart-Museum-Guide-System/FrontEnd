import '../../widgets/backend_panel.dart';
import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../services/backend_api.dart';

class SupportRefundScreen extends StatefulWidget {
  const SupportRefundScreen({super.key});
  @override
  State<SupportRefundScreen> createState() => _SupportRefundScreenState();
}

class _SupportRefundScreenState extends State<SupportRefundScreen> {
  final _subject = TextEditingController(), _body = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  late Future<List<Map<String, dynamic>>> _tickets = BackendApi.list(
    'complaints/me',
  );
  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BackendApi.request(
        'complaints',
        method: 'POST',
        body: {'subject': _subject.text.trim(), 'body': _body.text.trim()},
      );
      if (!mounted) return;
      _subject.clear();
      _body.clear();
      setState(() => _tickets = BackendApi.list('complaints/me'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu tới hệ thống.')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Hỗ trợ & khiếu nại',
    children: [
      const Notice(
        'Bạn có thể gửi vấn đề về dịch vụ hoặc đơn hàng. Việc gửi yêu cầu không tự động hoàn tiền; hệ thống chưa hỗ trợ hoàn tiền trực tiếp.',
      ),
      const SizedBox(height: 16),
      Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _subject,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
            ),
            TextFormField(
              controller: _body,
              maxLength: 5000,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Nội dung và mã đơn hàng (nếu có)',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập nội dung' : null,
            ),
            if (_error != null) Notice(_error!),
            PrimaryButton(
              label: _busy ? 'Đang gửi…' : 'Gửi yêu cầu',
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
      const SectionHeading('Yêu cầu của tôi'),
      TextButton(
        onPressed: () =>
            setState(() => _tickets = BackendApi.list('complaints/me')),
        child: const Text('Tải lại'),
      ),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _tickets,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          if (snapshot.data!.isEmpty) {
            return const Notice('Bạn chưa gửi yêu cầu nào.');
          }
          return Column(
            children: snapshot.data!
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['subject'], style: AppTextStyles.sectionTitle),
                          Text(t['body']),
                          Text('Trạng thái: ${backendStatus(t['status'])}'),
                          TextButton(
                            onPressed: () => openPage(
                              context,
                              ComplaintDetailScreen(id: t['id'] as int),
                            ),
                            child: const Text('Xem quá trình xử lý'),
                          ),
                          if (t['resolutionNote'] != null)
                            Text(t['resolutionNote']),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Chi tiết yêu cầu',
    children: [
      BackendPanel(
        resourceKey: 'complaint:$id',
        load: () => BackendApi.request('complaints/me/$id'),
        builder: (data, reload) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(data['subject'], style: AppTextStyles.pageTitle),
            Text(data['body']),
            Text(backendStatus(data['status'])),
            Text('Ngày gửi: ${data['createdAt']}'),
            if (data['resolutionNote'] != null)
              Text('Phản hồi xử lý: ${data['resolutionNote']}'),
            TextButton(
              onPressed: reload,
              child: const Text('Cập nhật tiến độ'),
            ),
          ],
        ),
      ),
    ],
  );
}
