import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';

class VisionCandidate {
  final int artifactId;
  final double score;

  const VisionCandidate({required this.artifactId, required this.score});

  factory VisionCandidate.fromJson(Map<String, dynamic> json) => VisionCandidate(
    artifactId: (json['artifactId'] ?? json['artifact_id'] ?? 0) as int,
    score: (json['similarity'] ?? json['score'] ?? 0.0).toDouble(),
  );
}

class VisionMatchResult {
  final bool matched;
  final int? artifactId;
  final double similarity;
  final double margin;
  final bool requiresConfirmation;
  final List<VisionCandidate> topCandidates;
  final String? message;

  const VisionMatchResult({
    required this.matched,
    this.artifactId,
    this.similarity = 0.0,
    this.margin = 0.0,
    this.requiresConfirmation = false,
    this.topCandidates = const [],
    this.message,
  });

  factory VisionMatchResult.fromJson(Map<String, dynamic> json) {
    final candidatesRaw = json['topCandidates'] ?? json['top_candidates'];
    final candidates = <VisionCandidate>[];
    if (candidatesRaw is List) {
      for (final c in candidatesRaw) {
        if (c is Map<String, dynamic>) {
          candidates.add(VisionCandidate.fromJson(c));
        }
      }
    }

    return VisionMatchResult(
      matched: json['matched'] == true,
      artifactId: json['artifactId'] as int?,
      similarity: (json['similarity'] ?? 0.0).toDouble(),
      margin: (json['margin'] ?? 0.0).toDouble(),
      requiresConfirmation: json['requiresConfirmation'] == true,
      topCandidates: candidates,
      message: json['message'] as String?,
    );
  }
}

class VisionApiService {
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.visionHealthUrl))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'status': 'unreachable', 'statusCode': res.statusCode};
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  static Future<VisionMatchResult> recognizeArtifact(
    Uint8List imageBytes, {
    String filename = 'camera_capture.jpg',
    String? serviceKey,
  }) async {
    final uri = Uri.parse('${ApiConfig.visionRecognitionsUrl}?top_k=3');
    final request = http.MultipartRequest('POST', uri);

    // Optional service key header (defaults to empty when called via proxy or open PoC)
    if (serviceKey != null && serviceKey.isNotEmpty) {
      request.headers['X-Service-Key'] = serviceKey;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      String detail = 'Lỗi nhận diện thị giác (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('detail')) {
          detail = decoded['detail'].toString();
        }
      } catch (_) {}
      throw Exception(detail);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return VisionMatchResult.fromJson(data);
  }
}
