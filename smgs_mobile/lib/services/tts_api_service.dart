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
          .get(
            Uri.parse('${ApiConfig.baseUrl}/tts/health'),
            headers: TokenManager.authHeaders,
          )
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
        '${ApiConfig.baseUrl}/tts/speech:$language:${clampedSpeed.toStringAsFixed(2)}:$cleanText';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/tts/speech');
    final response = await http
        .post(
          url,
          headers: {...TokenManager.authHeaders, 'Accept': 'audio/wav'},
          body: jsonEncode({
            'text': cleanText,
            'language': language.startsWith('vi') ? 'vi-VN' : 'en-US',
            // Kept for API clients that synthesize at the selected speed.
            // The playback UI still applies the rate locally as well.
            'speed': clampedSpeed,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      String detail = 'Lỗi tạo giọng đọc (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map &&
            (decoded.containsKey('detail') || decoded.containsKey('message'))) {
          detail = (decoded['detail'] ?? decoded['message']).toString();
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

  /// Resolve a BE-protected media URL to a short-lived storage URL. The native
  /// player can then stream/range-read audio without downloading the whole WAV
  /// into memory first. The signed URL is created only after BE access checks.
  static Future<String?> resolvePublishedPlaybackUrl(String url) async {
    final source = Uri.parse(url);
    if (!source.isAbsolute || !['https', 'http'].contains(source.scheme)) {
      throw const FormatException('Địa chỉ bản thu âm không hợp lệ.');
    }

    final backend = Uri.parse(ApiConfig.baseUrl);
    final match = RegExp(r'/api/artifacts/(\d+)/media/(\d+)/file/?$')
        .firstMatch(source.path);
    if (source.origin != backend.origin || match == null) return url;

    final endpoint = Uri.parse(
      '${ApiConfig.baseUrl}/artifacts/${match.group(1)}/media/${match.group(2)}/playback-url',
    );
    final response = await http
        .get(endpoint, headers: TokenManager.authHeaders)
        .timeout(const Duration(seconds: 10));
    // Keep the app compatible while an older BE instance is still rolling out.
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      String detail = 'Chưa lấy được đường dẫn phát audio.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] is String) {
          detail = decoded['message'] as String;
        }
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body);
    final playbackUrl = decoded is Map ? decoded['data'] : null;
    final uri = playbackUrl is String ? Uri.tryParse(playbackUrl) : null;
    if (uri == null || !uri.isAbsolute || !['https', 'http'].contains(uri.scheme)) {
      throw const FormatException('Máy chủ trả về đường dẫn phát audio không hợp lệ.');
    }
    return uri.toString();
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
