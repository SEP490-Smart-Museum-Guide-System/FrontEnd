import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';

class SpeechResult {
  final Uint8List audioBytes;
  final String voice;
  final bool cacheHit;
  final int statusCode;

  const SpeechResult({
    required this.audioBytes,
    required this.voice,
    required this.cacheHit,
    this.statusCode = 200,
  });

  int get byteLength => audioBytes.length;
}

class TtsApiService {
  // Client-side cache to minimize repetitive synthesis calls
  static final Map<String, SpeechResult> _cache = {};

  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.ttsHealthUrl))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'status': 'unreachable', 'statusCode': res.statusCode};
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  static Future<SpeechResult> synthesizeSpeech(
    String text, {
    double speed = 1.0,
    String language = 'vi-VN',
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw ArgumentError('Nội dung thuyết minh không được để trống');
    }

    // Clamp speed between 0.75 and 1.25 as enforced by TTS service schema
    final clampedSpeed = speed.clamp(0.75, 1.25);
    final cacheKey = '$language:${clampedSpeed.toStringAsFixed(2)}:$cleanText';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final url = Uri.parse(ApiConfig.ttsSpeechUrl);
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'audio/wav',
          },
          body: jsonEncode({
            'text': cleanText,
            'speed': clampedSpeed,
            'language': language.startsWith('vi') ? 'vi-VN' : language,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      String detail = 'Lỗi tạo giọng đọc (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('detail')) {
          detail = decoded['detail'].toString();
        }
      } catch (_) {}
      throw Exception(detail);
    }

    final voice = response.headers['x-tts-voice'] ?? 'Vietnamese Neural';
    final cacheHit = response.headers['x-tts-cache'] == 'HIT';
    final result = SpeechResult(
      audioBytes: response.bodyBytes,
      voice: voice,
      cacheHit: cacheHit,
      statusCode: response.statusCode,
    );

    _cache[cacheKey] = result;
    return result;
  }
}
