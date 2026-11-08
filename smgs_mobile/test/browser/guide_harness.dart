// Visual/browser fixture only. The shipped app uses catalog data and the real BE endpoint.
import 'package:flutter/material.dart';
import 'package:smgs_mobile/core/theme/app_theme.dart';
import 'package:smgs_mobile/models/artifact.dart';
import 'package:smgs_mobile/screens/ai_guide/ai_guide_screen.dart';
import 'package:smgs_mobile/widgets/heritage_decoration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: HeritagePaper(
        child: AiGuideScreen(
          artifact: Artifact.fromBackendJson({
            'id': 17,
            'museumId': 1,
            'name': 'Bình gốm · kiểm thử giao diện',
          }),
        ),
      ),
    ),
  );
}
