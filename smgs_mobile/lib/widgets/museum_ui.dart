import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'heritage_decoration.dart';
import 'heritage_motion.dart';
export '../core/theme/app_colors.dart';
export '../core/theme/app_text_styles.dart';
export 'heritage_art.dart';
export 'primary_button.dart';
export 'secondary_button.dart';
export 'heritage_decoration.dart';
export 'heritage_motion.dart';

void openPage(BuildContext context, Widget page) {
  final reduced = reduceHeritageMotion(context);
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: reduced ? Duration.zero : HeritageMotion.standard,
      reverseTransitionDuration: reduced ? Duration.zero : HeritageMotion.fast,
      pageBuilder: (context, animation, secondaryAnimation) =>
          HeritagePaper(child: page),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = animation.drive(CurveTween(curve: HeritageMotion.curve));
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: curve.drive(
              Tween(begin: const Offset(0, 0.018), end: Offset.zero),
            ),
            child: child,
          ),
        );
      },
    ),
  );
}

class MuseumPage extends StatelessWidget {
  const MuseumPage({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
    this.subtitle,
    this.back = false,
  });
  final String title;
  final String? eyebrow, subtitle;
  final bool back;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final body = SoftEntrance(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            if (eyebrow != null) ...[
              Row(
                children: [
                  Expanded(child: Eyebrow(eyebrow!)),
                  const SizedBox(width: 12),
                  const HeritageSeal(size: 34),
                ],
              ),
              const SizedBox(height: 16),
            ],
            AnimatedSwitcher(
              duration: reduceHeritageMotion(context)
                  ? Duration.zero
                  : HeritageMotion.standard,
              switchInCurve: HeritageMotion.curve,
              child: Text(
                title,
                key: ValueKey(title),
                style: AppTextStyles.display.copyWith(
                  color: AppColors.deepBurgundy,
                  fontSize: 32,
                  height: 1.3,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: reduceHeritageMotion(context)
                    ? Duration.zero
                    : HeritageMotion.fast,
                child: Text(
                  subtitle!,
                  key: ValueKey(subtitle),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Container(width: 40, height: 2, color: AppColors.deepBurgundy),
                const Expanded(child: Divider(height: 1, thickness: 1)),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
    return back
        ? Scaffold(
            appBar: AppBar(title: const Text('Cẩm nang bảo tàng')),
            body: body,
          )
        : body;
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.light = false});
  final String text;
  final bool light;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTextStyles.caption.copyWith(
      letterSpacing: 1.8,
      fontWeight: FontWeight.w600,
      color: light ? AppColors.antiqueIvory : AppColors.deepBurgundy,
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gold = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool gold;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: gold ? AppColors.mutedGold : AppColors.border),
    ),
    child: child,
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 14),
    child: Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              action!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.deepBurgundy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: HoverLift(
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.antiqueIvory,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 24, color: AppColors.deepBurgundy),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: AppColors.deepBurgundy),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
    ],
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.search_off_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        Icon(icon, size: 36, color: AppColors.mutedGold),
        const SizedBox(height: 16),
        Text(
          title,
          style: AppTextStyles.sectionTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Future<void> showReading(
  BuildContext context, {
  required String title,
  required String text,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 500),
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.pageTitle),
          const SizedBox(height: 16),
          Text(text, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Đóng'),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
