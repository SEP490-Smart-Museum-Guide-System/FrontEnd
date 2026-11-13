import 'package:flutter/material.dart';

void showEarnedBadges(BuildContext context, dynamic badges) {
  if (badges is! List || badges.isEmpty) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Bạn vừa đạt huy hiệu: ${badges.map((b) => b['name']).join(', ')}',
      ),
      duration: const Duration(seconds: 6),
    ),
  );
}
