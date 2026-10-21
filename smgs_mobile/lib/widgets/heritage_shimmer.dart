import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class HeritageShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const HeritageShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<HeritageShimmer> createState() => _HeritageShimmerState();
}

class _HeritageShimmerState extends State<HeritageShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (_controller.value * 3.0), -0.3),
              end: Alignment(-0.5 + (_controller.value * 3.0), 0.3),
              colors: [
                AppColors.softSand,
                AppColors.antiqueIvory,
                AppColors.softSand,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// Thẻ khung xương (Skeleton) bảo tàng theo tỷ lệ thẻ MuseumCard
class HeritageMuseumCardSkeleton extends StatelessWidget {
  const HeritageMuseumCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeritageShimmer(
            width: double.infinity,
            height: 200,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeritageShimmer(width: 140, height: 14),
                const SizedBox(height: 12),
                const HeritageShimmer(width: double.infinity, height: 26),
                const SizedBox(height: 10),
                const HeritageShimmer(width: 220, height: 16),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    HeritageShimmer(width: 24, height: 24, borderRadius: 12),
                    SizedBox(width: 10),
                    HeritageShimmer(width: 160, height: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
