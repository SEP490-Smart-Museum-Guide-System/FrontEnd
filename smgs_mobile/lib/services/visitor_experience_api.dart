import 'dart:math';
import 'artifact_scan_service.dart';
import 'backend_api.dart';

class VisitorSession {
  static Map<String, dynamic>? activeVisit;
  static void clear() => activeVisit = null;
}

class ScanRequest {
  ScanRequest(String input, {this.visitId, this.imageMatch = false})
    : code = ArtifactScanService.extractCode(input),
      requestId = uuid();
  final String code, requestId;
  final int? visitId;
  final bool imageMatch;
  static String uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final text = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${text.substring(0, 8)}-${text.substring(8, 12)}-${text.substring(12, 16)}-${text.substring(16, 20)}-${text.substring(20)}';
  }

  Future<Map<String, dynamic>> record() async {
    final result = await BackendApi.request(
      'recognitions/qr',
      method: 'POST',
      body: {
        'qrCode': code,
        'visitId': visitId,
        'requestId': requestId,
        'method': imageMatch ? 'image' : 'qr',
      },
    );
    return Map<String, dynamic>.from(result);
  }
}

class VisitorExperienceApi {
  static Future<void> recordDetailView(int artifactId, String requestId) async {
    await BackendApi.request(
      'artifacts/$artifactId/detail-views',
      method: 'POST',
      body: {'requestId': requestId},
    );
  }

  static Future<Map<String, dynamic>> startVisit(
    int museumId, {
    int? tourId,
    String? personalizedTourId,
  }) async {
    final data = Map<String, dynamic>.from(
      await BackendApi.request(
        'visits',
        method: 'POST',
        body: {
          'museumId': museumId,
          'tourId': tourId,
          'personalizedTourId': ?personalizedTourId,
        },
      ),
    );
    VisitorSession.activeVisit = data;
    return data;
  }

  static Future<Map<String, dynamic>> progress(int visitId) async =>
      Map<String, dynamic>.from(
        await BackendApi.request('visits/$visitId/progress'),
      );
  static Future<Map<String, dynamic>> location(int visitId) async =>
      Map<String, dynamic>.from(
        await BackendApi.request(
          'visitor-navigation/location?visitId=$visitId',
        ),
      );
  static Future<Map<String, dynamic>> route(
    int visitId,
    int mapId, {
    int? artifactId,
    bool accessible = false,
  }) async => Map<String, dynamic>.from(
    await BackendApi.request(
      'visitor-navigation/route?visitId=$visitId&mapId=$mapId&accessibleOnly=$accessible${artifactId == null ? '' : '&artifactId=$artifactId'}',
    ),
  );

  static Future<Map<String, dynamic>> completeVisit(int visitId) async {
    final result = await BackendApi.request(
      'visits/$visitId/complete',
      method: 'POST',
    );
    if (VisitorSession.activeVisit?['id'] == visitId) {
      VisitorSession.clear();
    }
    return Map<String, dynamic>.from(result);
  }

  static Future<List<Map<String, dynamic>>> getMyVisits({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final uri = Uri(queryParameters: query);
    final result = await BackendApi.request('visits/me?${uri.query}');
    if (result is List) return result.cast<Map<String, dynamic>>();
    if (result is Map && result['items'] is List) {
      return (result['items'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>> submitFeedback({
    required int visitId,
    required int overallRating,
    int? contentRating,
    int? tourRating,
    int? chatbotRating,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'visitId': visitId,
      'overallRating': overallRating,
      if (contentRating != null) 'contentRating': contentRating,
      if (tourRating != null) 'tourRating': tourRating,
      if (chatbotRating != null) 'chatbotRating': chatbotRating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    };
    final result = await BackendApi.request(
      'feedbacks',
      method: 'POST',
      body: body,
    );
    return Map<String, dynamic>.from(result);
  }

  static Future<List<Map<String, dynamic>>> getMuseumFeedbacks(
    int museumId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final result = await BackendApi.request(
        'feedbacks/museum/$museumId?page=$page&pageSize=$pageSize',
      );
      if (result is List) return result.cast<Map<String, dynamic>>();
      if (result is Map && result['items'] is List) {
        return (result['items'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getVisitFeedback(int visitId) async {
    try {
      final result = await BackendApi.request('feedbacks/visit/$visitId');
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return null;
    }
  }

  /// Sửa đánh giá chuyến đi (PUT /api/feedbacks/{id})
  static Future<Map<String, dynamic>> updateFeedback({
    required int feedbackId,
    required int overallRating,
    int? contentRating,
    int? tourRating,
    int? chatbotRating,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'overallRating': overallRating,
      if (contentRating != null) 'contentRating': contentRating,
      if (tourRating != null) 'tourRating': tourRating,
      if (chatbotRating != null) 'chatbotRating': chatbotRating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    };
    final result = await BackendApi.request(
      'feedbacks/$feedbackId',
      method: 'PUT',
      body: body,
    );
    return Map<String, dynamic>.from(result);
  }

  /// Lấy chi tiết một lượt tham quan (GET /api/visits/{id})
  static Future<Map<String, dynamic>?> getVisit(int visitId) async {
    try {
      final result = await BackendApi.request('visits/$visitId');
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return null;
    }
  }

  /// Làm lại bài thi trắc nghiệm (POST /api/quiz-attempts/{id}/reset)
  static Future<Map<String, dynamic>> resetQuizAttempt(int attemptId) async {
    final result = await BackendApi.request(
      'quiz-attempts/$attemptId/reset',
      method: 'POST',
      body: {},
    );
    return Map<String, dynamic>.from(result);
  }

  /// WF-02 (F05): Lưu lộ trình tham quan vào danh sách cá nhân (POST /api/tours/saved-routes)
  static Future<Map<String, dynamic>> saveRoute({
    required int tourVersionId,
    required int availableMinutes,
    List<int>? topicIds,
  }) async {
    final result = await BackendApi.request(
      'tours/saved-routes',
      method: 'POST',
      body: {
        'tourVersionId': tourVersionId,
        'availableMinutes': availableMinutes,
        'topicIds': topicIds ?? [],
      },
    );
    return Map<String, dynamic>.from(result);
  }

  /// WF-02 (F05): Lấy danh sách lộ trình đã lưu của khách (GET /api/tours/saved-routes)
  static Future<List<Map<String, dynamic>>> getSavedRoutes({int? museumId}) async {
    try {
      final query = museumId != null ? '?museumId=$museumId' : '';
      final result = await BackendApi.request('tours/saved-routes$query');
      if (result is List) return result.cast<Map<String, dynamic>>();
      if (result is Map && result['items'] is List) {
        return (result['items'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// WF-02 (F05): Lấy chi tiết một lộ trình đã lưu (GET /api/tours/saved-routes/{id})
  static Future<Map<String, dynamic>> getSavedRoute(int id) async {
    final result = await BackendApi.request('tours/saved-routes/$id');
    return Map<String, dynamic>.from(result);
  }

  /// Lấy ngôn ngữ ưu tiên của tài khoản đã đăng nhập (GET /api/me/language)
  static Future<String?> getUserLanguage() async {
    try {
      final result = await BackendApi.request('me/language');
      if (result is Map && result['languageCode'] != null) {
        final code = result['languageCode'].toString().toLowerCase();
        return (code == 'en') ? 'en' : 'vi';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Cập nhật ngôn ngữ ưu tiên của tài khoản (PUT /api/me/language)
  static Future<bool> updateUserLanguage(String languageCode) async {
    try {
      final code = (languageCode == 'en') ? 'en' : 'vi';
      await BackendApi.request(
        'me/language',
        method: 'PUT',
        body: {'languageCode': code},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
