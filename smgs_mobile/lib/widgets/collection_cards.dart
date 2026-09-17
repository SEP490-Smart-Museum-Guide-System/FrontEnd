import 'package:flutter/material.dart';

import '../models/museum.dart';
import '../models/artifact.dart';
import '../data/mock/mock_museums.dart';
import '../screens/museum/museum_detail_screen.dart';
import '../screens/artifact/artifact_detail_screen.dart';
import 'museum_ui.dart';

class MuseumCard extends StatelessWidget {
  const MuseumCard({super.key, required this.museum, this.featured = false});
  final Museum museum;
  final bool featured;
  String get _heroTag =>
      'museum-photo:${featured ? 'home' : 'collection'}:${museum.id}';
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => openPage(
        context,
        MuseumDetailScreen(museum: museum, heroTag: _heroTag),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              HeroMode(
                enabled: !reduceHeritageMotion(context),
                child: Hero(
                  tag: _heroTag,
                  flightShuttleBuilder: (
                    context,
                    animation,
                    direction,
                    from,
                    to,
                  ) => MuseumPhoto(museumId: museum.id, height: 300),
                  child: ParallaxPhoto(
                    height: featured ? 238 : 200,
                    child: MuseumPhoto(
                      museumId: museum.id,
                      height: featured ? 238 : 200,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: AppColors.antiqueIvory,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.deepBurgundy,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'HÀ NỘI',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.deepBurgundy,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (featured)
                Positioned(
                  bottom: 0,
                  right: 18,
                  child: Container(
                    width: 48,
                    height: 58,
                    color: AppColors.deepBurgundy,
                    alignment: Alignment.center,
                    child: const HeritageSeal(size: 34, light: true),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 24, height: 1, color: AppColors.mutedGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Eyebrow('${museum.category} · Di sản Việt'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  museum.name,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.deepBurgundy,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(museum.shortIntro, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_outlined,
                        size: 19,
                        color: AppColors.deepBurgundy,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bước vào bảo tàng',
                          style: AppTextStyles.buttonText.copyWith(
                            color: AppColors.deepBurgundy,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 22,
                        color: AppColors.deepBurgundy,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class ArtifactCard extends StatelessWidget {
  const ArtifactCard({super.key, required this.artifact});
  final Artifact artifact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPage(
          context,
          ArtifactDetailScreen(
            artifact: artifact,
            museumName: mockMuseums
                .firstWhere((m) => m.id == artifact.museumId)
                .name,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 86,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: artifact.id == 'artifact_1'
                      ? Image.asset(
                          'assets/images/ngoc-lu-web.jpg',
                          height: 108,
                          fit: BoxFit.cover,
                          semanticLabel: 'Trống đồng Ngọc Lũ',
                        )
                      : HeritageArt(kind: artifact.id, height: 108),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.category.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.deepBurgundy,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      artifact.name,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: AppColors.deepBurgundy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(artifact.period, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
