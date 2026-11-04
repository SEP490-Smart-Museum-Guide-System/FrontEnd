import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import 'token_manager.dart';

class SpeechResult {
  final Uint8List audioBytes;
  final String voice;
  final bool cacheHit;
  final int statusCode;
  final String mimeType;

  const SpeechResult({
    required this.audioBytes,
    required this.voice,
    required this.cacheHit,
    this.statusCode = 200,
    this.mimeType = 'audio/wav',
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
    final cacheKey =
        '${ApiConfig.ttsSpeechUrl}:$language:${clampedSpeed.toStringAsFixed(2)}:$cleanText';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final url = Uri.parse(ApiConfig.ttsSpeechUrl);
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json', 'Accept': 'audio/wav'},
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

    final bytes = response.bodyBytes;
    if (bytes.length < 44 ||
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'RIFF' ||
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) != 'WAVE') {
      throw const FormatException(
        'Máy chủ chưa trả về tệp âm thanh WAV hợp lệ.',
      );
    }

    final voice = response.headers['x-tts-voice'] ?? 'Vietnamese Neural';
    final cacheHit = response.headers['x-tts-cache'] == 'HIT';
    final result = SpeechResult(
      audioBytes: bytes,
      voice: voice,
      cacheHit: cacheHit,
      statusCode: response.statusCode,
    );

    if (_cache.length >= 16) _cache.remove(_cache.keys.first);
    _cache[cacheKey] = result;
    return result;
  }

  /// Download the published recording; send credentials only to our BE origin.
  static Future<SpeechResult> fetchPublishedAudio(String url) async {
    final uri = Uri.parse(url);
    if (!uri.isAbsolute || !['https', 'http'].contains(uri.scheme)) {
      throw const FormatException('Địa chỉ bản thu âm không hợp lệ.');
    }
    final backend = Uri.parse(ApiConfig.baseUrl);
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'audio/*',
            if (uri.origin == backend.origin) ...TokenManager.authHeaders,
          },
        )
        .timeout(const Duration(seconds: 25));
    final type = (response.headers['content-type'] ?? '')
        .split(';')
        .first
        .trim()
        .toLowerCase();
    if (response.statusCode != 200 ||
        response.bodyBytes.isEmpty ||
        !(type.startsWith('audio/') || type == 'application/octet-stream')) {
      throw const FormatException('Chưa tải được bản thu âm của bảo tàng.');
    }
    return SpeechResult(
      audioBytes: response.bodyBytes,
      mimeType: type == 'application/octet-stream'
          ? _audioMimeType(response.bodyBytes)
          : type,
      voice: 'Bản thu bảo tàng',
      cacheHit: false,
    );
  }

  static String _audioMimeType(Uint8List bytes) {
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF') {
      return 'audio/wav';
    }
    if (bytes.length >= 4 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'OggS') {
      return 'audio/ogg';
    }
    return 'audio/mpeg';
  }
}
