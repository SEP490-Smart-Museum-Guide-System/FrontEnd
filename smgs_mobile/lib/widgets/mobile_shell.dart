import 'package:flutter/material.dart';

class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.child, this.bottomNavigationBar});
  final Widget child;
  final Widget? bottomNavigationBar;
  @override
  Widget build(BuildContext context) => SafeArea(child: child);
}
