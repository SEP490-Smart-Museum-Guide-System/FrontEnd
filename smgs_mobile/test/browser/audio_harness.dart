// Browser-only harness for the real NarrationPlayer and audio plugin.
import 'package:flutter/material.dart';
import 'package:smgs_mobile/widgets/narration_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(const MaterialApp(home: AudioHarness()));
}

class AudioHarness extends StatefulWidget {
  const AudioHarness({super.key});
  @override
  State<AudioHarness> createState() => _AudioHarnessState();
}

class _AudioHarnessState extends State<AudioHarness> {
  bool _visible = true;
  String _text = 'Bản thuyết minh dùng để kiểm tra bộ phát âm thanh.';
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_visible) NarrationPlayer(text: _text),
          TextButton(
            onPressed: () =>
                setState(() => _text = 'Nội dung thuyết minh mới.'),
            child: const Text('Đổi nội dung'),
          ),
          TextButton(
            onPressed: () => setState(() => _visible = false),
            child: const Text('Đóng trình phát'),
          ),
        ],
      ),
    ),
  );
}
