// HTTP fixtures belong in tests only; the application never imports this file.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'mock_museums.dart';

void apiTestWidgets(
  String description,
  Future<void> Function(ft.WidgetTester) callback,
) {
  ft.testWidgets(
    description,
    (tester) => http.runWithClient(
      () => callback(tester),
      () => MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/museums') {
          final keyword = request.url.queryParameters['keyword'] ?? '';
          final rows = mockMuseums
              .where(
                (m) =>
                    keyword.isEmpty ||
                    (keyword == 'ho chi minh' && m.id == 'museum_ho_chi_minh'),
              )
              .map(
                (m) => {
                  'id': m.id,
                  'name': m.name,
                  'address': m.location,
                  'description': m.description,
                  'openingHours': m.openingHours,
                  'isActive': true,
                },
              )
              .toList();
          return http.Response(
            jsonEncode({
              'data': {
                'items': rows,
                'page': 1,
                'totalPages': 1,
                'totalCount': rows.length,
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({'message': 'Chưa có dữ liệu kiểm thử cho $path'}),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ),
  );
}
