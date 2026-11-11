import 'backend_api.dart';

class PersonalizedTourApi {
  static Future<List<Map<String, dynamic>>> interests(int museumId) async =>
      (await BackendApi.request(
                'personalized-tours/interests?museumId=$museumId',
              )
              as List)
          .cast<Map<String, dynamic>>();

  static Future<Map<String, dynamic>> recommend(
    int museumId,
    int minutes,
    Iterable<String> interests,
  ) async => Map<String, dynamic>.from(
    await BackendApi.request(
      'personalized-tours/recommendations',
      method: 'POST',
      body: {
        'museumId': museumId,
        'availableMinutes': minutes,
        'interests': interests.toList(),
      },
      timeout: const Duration(seconds: 30),
    ),
  );

  static Future<Map<String, dynamic>> save(String id) async =>
      Map<String, dynamic>.from(
        await BackendApi.request(
          'personalized-tours',
          method: 'POST',
          body: {'recommendationId': id},
        ),
      );

  static Future<List<Map<String, dynamic>>> saved() async =>
      (await BackendApi.request('personalized-tours/me?pageSize=20') as List)
          .cast<Map<String, dynamic>>();
}
