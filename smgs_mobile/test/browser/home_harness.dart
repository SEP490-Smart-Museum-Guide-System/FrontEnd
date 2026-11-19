// Browser-only visual fixture. Never imported by lib/ or the visitor production entrypoint.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/core/theme/app_theme.dart';
import 'package:smgs_mobile/models/museum.dart';
import 'package:smgs_mobile/navigation/main_navigation.dart';
import 'package:smgs_mobile/services/app_services.dart';
import '../support/fake_services.dart';
import '../support/mock_museums.dart';

class VisualCatalog extends MockCatalogService {
  @override
  List<Museum> get museums => [
    mockMuseums.first.copyWith(
      imageUrl: 'assets/images/national-museum-web.jpg',
    ),
    mockMuseums.last.copyWith(
      imageUrl: 'assets/images/ho-chi-minh-museum-web.jpg',
    ),
  ];
}

void main() {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  AppServices.auth = MockAuthService();
  AppServices.catalog = VisualCatalog();
  http.runWithClient(
    () => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigation(),
      ),
    ),
    () => MockClient(
      (request) async => http.Response(
        jsonEncode({
          'data': request.url.path == '/api/visits/me'
              ? []
              : {'items': [], 'page': 1, 'totalPages': 1, 'totalCount': 0},
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
}
