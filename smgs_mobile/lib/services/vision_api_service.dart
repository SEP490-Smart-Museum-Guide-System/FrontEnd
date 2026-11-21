import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import 'discovery_api_service.dart';
import 'token_manager.dart';

class VisionCandidate {
  final int artifactId;
  final double score;

  const VisionCandidate({required this.artifactId, required this.score});

  factory VisionCandidate.fromJson(Map<String, dynamic> json) =>
      VisionCandidate(
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
    final candidatesRaw =
        json['candidates'] ?? json['topCandidates'] ?? json['top_candidates'];
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
          .get(
            Uri.parse(ApiConfig.visionHealthUrl),
            headers: TokenManager.authHeaders,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return DiscoveryApiService.decodeResponse(res)['data']
            as Map<String, dynamic>;
      }
      return {'status': 'unreachable', 'statusCode': res.statusCode};
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  static Future<VisionMatchResult> recognizeArtifact(
    Uint8List imageBytes, {
    String filename = 'camera_capture.jpg',
    int? museumId,
  }) async {
    final uri = Uri.parse(ApiConfig.visionRecognitionsUrl).replace(
      queryParameters: {
        'top_k': '3',
        if (museumId != null) 'museum_id': '$museumId',
      },
    );
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(
      {...TokenManager.authHeaders}..remove('Content-Type'),
    );

    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
    );

    final response = await request
        .send()
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 60));
    final data =
        DiscoveryApiService.decodeResponse(response)['data']
            as Map<String, dynamic>;
    return VisionMatchResult.fromJson(data);
  }
}
