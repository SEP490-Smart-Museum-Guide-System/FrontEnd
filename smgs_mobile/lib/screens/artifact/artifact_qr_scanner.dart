import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/artifact_scan_service.dart';
import '../../widgets/museum_ui.dart';

class ArtifactQrScanner extends StatefulWidget {
  const ArtifactQrScanner({super.key});
  @override
  State<ArtifactQrScanner> createState() => _ArtifactQrScannerState();
}

class _ArtifactQrScannerState extends State<ArtifactQrScanner> {
  final _input = TextEditingController();
  bool _camera = false, _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _scan(String value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _camera = false;
      _error = null;
    });
    try {
      final data = await ArtifactScanService.scan(value);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MuseumPage(
            back: true,
            title: data['name'] as String,
            subtitle: data['museumName'] as String,
            children: [
              if (data['code'] != null) Text('Mã hiện vật: ${data['code']}'),
              if (data['galleryId'] != null)
                Text('Phòng trưng bày: ${data['galleryId']}'),
              if ((data['contents'] as List).isEmpty)
                const Notice('Hiện vật chưa có nội dung được xuất bản.'),
              for (final content in data['contents'] as List) ...[
                const SizedBox(height: 20),
                Text(
                  '${content['title']} (${content['languageCode']})',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  content['description'] as String,
                  style: AppTextStyles.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      );
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'Máy chủ phản hồi chậm. Vui lòng thử lại.');
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Quét mã hiện vật',
    subtitle: 'Quét mã đặt cạnh hiện vật để xem thông tin.',
    children: [
      if (_camera)
        SizedBox(
          height: 280,
          child: MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _scan(barcode.rawValue!);
                  break;
                }
              }
            },
            errorBuilder: (context, error) => const Center(
              child: Notice(
                'Không mở được camera. Hãy cấp quyền máy ảnh hoặc nhập mã bên dưới. Trên web, camera cần HTTPS hoặc localhost.',
              ),
            ),
          ),
        ),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) Notice(_error!),
      const SizedBox(height: 16),
      PrimaryButton(
        label: _camera ? 'Tắt camera' : 'Mở camera quét QR',
        icon: Icons.qr_code_scanner,
        onPressed: _busy ? null : () => setState(() => _camera = !_camera),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _input,
        enabled: !_busy,
        decoration: const InputDecoration(
          labelText: 'Mã QR hoặc URL trên mã QR',
        ),
        onSubmitted: _scan,
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Xem thông tin hiện vật',
        icon: Icons.search,
        onPressed: _busy ? null : () => _scan(_input.text),
      ),
    ],
  );
}

