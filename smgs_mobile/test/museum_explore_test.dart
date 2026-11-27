import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/screens/explore/museum_explore_screen.dart';
import 'package:smgs_mobile/widgets/collection_cards.dart';

import 'widget_test.dart' show host, screenSize;

void main() {
  testWidgets(
    'Explore expands categories and sends search and category to the server',
    (tester) async {
      await screenSize(tester, const Size(390, 920));
      final requests = <Uri>[];
      final categories = [
        'Lịch sử',
        'Văn hóa',
        'Mỹ thuật – Nghệ thuật',
        'Quân sự – Chiến tranh',
        'Dân tộc học',
      ];
      final client = MockClient((request) async {
        final uri = request.url;
        requests.add(uri);
        final isCategories = uri.path.endsWith('/museum-categories');
        final data = isCategories
            ? [
                for (var i = 0; i < categories.length; i++)
                  {'id': i + 1, 'code': 'category-$i', 'name': categories[i]},
              ]
            : {
                'page': 1,
                'totalPages': 1,
                'totalCount': 1,
                'items': [
                  {
                    'id': 1,
                    'name': 'Bảo tàng kiểm thử',
                    'description': 'Lịch sử',
                  },
                ],
              };
        return http.Response(
          jsonEncode({'data': data}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(host(const MuseumExploreScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Khám phá kho tàng di sản Việt Nam'), findsOneWidget);
        expect(find.text('Dân tộc học'), findsNothing);
        await tester.tap(find.text('Xem thêm danh mục'));
        await tester.pumpAndSettle();
        expect(find.text('Dân tộc học'), findsOneWidget);
        await tester.tap(find.text('Dân tộc học'));
        await tester.pumpAndSettle();
        expect(requests.last.queryParameters['categoryId'], '5');
        await tester.tap(find.text('Thu gọn'));
        await tester.pumpAndSettle();
        expect(find.text('Dân tộc học'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'di sản');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(
          requests.last.queryParameters,
          containsPair('keyword', 'di sản'),
        );
        expect(requests.last.queryParameters, containsPair('categoryId', '5'));
        expect(find.byType(MuseumCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => client);
    },
  );
}
