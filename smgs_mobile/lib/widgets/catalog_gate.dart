import 'package:flutter/material.dart';
import '../services/app_services.dart';
import '../navigation/main_navigation.dart';
import 'museum_ui.dart';

class CatalogGate extends StatefulWidget {
  const CatalogGate({super.key});
  @override
  State<CatalogGate> createState() => _CatalogGateState();
}

class _CatalogGateState extends State<CatalogGate> {
  late Future<void> _load = AppServices.catalog.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _load,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (snapshot.hasError)
        return MuseumPage(
          title: 'Chưa tải được dữ liệu',
          children: [
            Notice(snapshot.error.toString()),
            PrimaryButton(
              label: 'Thử lại',
              onPressed: () =>
                  setState(() => _load = AppServices.catalog.load()),
            ),
            TextButton(
              onPressed: AppServices.auth.logout,
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      return const MainNavigation();
    },
  );
}
