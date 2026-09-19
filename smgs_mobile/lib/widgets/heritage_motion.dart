import 'package:flutter/material.dart';

import 'heritage_decoration.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

bool reduceHeritageMotion(BuildContext context) =>
    // Web semantics enables accessibleNavigation even without reduced motion.
    // Only the user's explicit motion preference should disable these effects.
    MediaQuery.disableAnimationsOf(context);

abstract final class HeritageMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 280);
  static const reveal = Duration(milliseconds: 440);
  static const curve = Curves.easeOutCubic;
}

/// A restrained entrance used for complete pages and important content blocks.
class SoftEntrance extends StatelessWidget {
  const SoftEntrance({super.key, required this.child, this.offset = 14});

  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (reduceHeritageMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: HeritageMotion.standard,
      curve: HeritageMotion.curve,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, offset * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

/// Gives pointer users quiet feedback without changing the mobile layout.
class HoverLift extends StatefulWidget {
  const HoverLift({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final animate = widget.enabled && !reduceHeritageMotion(context);
    return MouseRegion(
      onEnter: animate ? (_) => setState(() => _hovered = true) : null,
      onExit: animate ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedScale(
        scale: animate && _hovered ? 1.008 : 1,
        duration: HeritageMotion.fast,
        curve: HeritageMotion.curve,
        alignment: Alignment.center,
        child: AnimatedSlide(
          offset: animate && _hovered ? const Offset(0, -0.008) : Offset.zero,
          duration: HeritageMotion.fast,
          curve: HeritageMotion.curve,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Reveals a section once, when it actually enters the scroll viewport.
/// Off-screen cached children do not start their animation prematurely.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({super.key, required this.child});
  final Widget child;
  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final _animation = AnimationController(
    vsync: this,
    duration: HeritageMotion.reveal,
  );
  late final _curve = CurvedAnimation(
    parent: _animation,
    curve: Curves.easeOutCubic,
  );
  ScrollableState? _scrollable;
  ScrollPosition? _position;
  bool _shown = false;
  bool _queued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    _scrollable = scrollable;
    // ScrollableState can retain its identity while replacing its position
    // (for example when web accessibility changes the scrolling physics).
    if (scrollable?.position != _position) {
      _position?.removeListener(_scheduleCheck);
      _position = scrollable?.position;
      _position?.addListener(_scheduleCheck);
    }
    if (reduceHeritageMotion(context)) {
      _shown = true;
      _animation.value = 1;
    } else {
      _scheduleCheck();
    }
  }

  void _scheduleCheck() {
    if (_shown || _queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (!mounted || _shown) return;
      final box = context.findRenderObject();
      final viewport = _scrollable?.context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      if (viewport is RenderBox && viewport.hasSize) {
        final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
        if (top >= viewport.size.height - 48 || top + box.size.height <= 0) {
          return;
        }
      }
      _shown = true;
      _position?.removeListener(_scheduleCheck);
      _animation.forward();
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    _curve.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FadeTransition(
      opacity: _curve,
      alwaysIncludeSemantics: true,
      child: AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 22 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Repaints only the clipped photograph as the surrounding list scrolls.
class ParallaxPhoto extends StatefulWidget {
  const ParallaxPhoto({super.key, required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  State<ParallaxPhoto> createState() => _ParallaxPhotoState();
}

class _ParallaxPhotoState extends State<ParallaxPhoto> {
  final _frameKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    return SizedBox(
      key: _frameKey,
      height: widget.height,
      width: double.infinity,
      child: scrollable == null || reduceHeritageMotion(context)
          ? widget.child
          : RepaintBoundary(
              child: Flow(
                clipBehavior: Clip.hardEdge,
                delegate: _PhotoFlow(scrollable, _frameKey),
                children: [widget.child],
              ),
            ),
    );
  }
}

class _PhotoFlow extends FlowDelegate {
  _PhotoFlow(this.scrollable, this.frameKey)
    : super(repaint: scrollable.position);
  final ScrollableState scrollable;
  final GlobalKey frameKey;
  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(
        Size(constraints.maxWidth, constraints.maxHeight + 72),
      );
  @override
  void paintChildren(FlowPaintingContext context) {
    final frame = frameKey.currentContext?.findRenderObject();
    final viewport = scrollable.context.findRenderObject();
    var fraction = 0.5;
    if (frame is RenderBox &&
        viewport is RenderBox &&
        viewport.size.height > 0) {
      final center = frame.localToGlobal(
        Offset(0, frame.size.height / 2),
        ancestor: viewport,
      );
      fraction = (center.dy / viewport.size.height).clamp(0.0, 1.0);
    }
    context.paintChild(
      0,
      transform: Matrix4.translationValues(0, -72 * fraction, 0),
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoFlow oldDelegate) =>
      oldDelegate.scrollable != scrollable || oldDelegate.frameKey != frameKey;
}

/// A photo-led detail page with natural scrolling and a pinned compact title.
class StoryScaffold extends StatelessWidget {
  const StoryScaffold({
    super.key,
    required this.title,
    required this.photo,
    required this.children,
    this.heroTag,
    this.actions = const [],
  });
  final String title;
  final Widget photo;
  final List<Widget> children, actions;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final reduced = reduceHeritageMotion(context);
    final image = heroTag == null
        ? photo
        : HeroMode(
            enabled: !reduced,
            child: Hero(tag: heroTag!, child: photo),
          );
    return Scaffold(
      body: HeritagePaper(
        child: CustomScrollView(
          slivers: [
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final collapsed = ((constraints.scrollOffset - 160) / 70).clamp(
                  0.0,
                  1.0,
                );
                return SliverAppBar(
                  pinned: true,
                  expandedHeight: 300,
                  backgroundColor: AppColors.antiqueIvory,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color: AppColors.antiqueIvory,
                      borderRadius: BorderRadius.circular(10),
                      child: const BackButton(),
                    ),
                  ),
                  title: ExcludeSemantics(
                    excluding: collapsed < 1,
                    child: Opacity(
                      opacity: reduced ? (collapsed > 0.5 ? 1 : 0) : collapsed,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  actions: actions
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 2,
                          ),
                          child: Material(
                            color: AppColors.antiqueIvory,
                            borderRadius: BorderRadius.circular(10),
                            child: action,
                          ),
                        ),
                      )
                      .toList(),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: reduced
                        ? CollapseMode.none
                        : CollapseMode.parallax,
                    background: image,
                  ),
                );
              },
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList.list(children: children),
            ),
          ],
        ),
      ),
    );
  }
}
