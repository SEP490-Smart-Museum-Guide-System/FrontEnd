import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/museum.dart';
import '../screens/museum/museum_detail_screen.dart';

class MuseumDiscoveryCard extends StatelessWidget {
  final Museum museum;
  final bool isSelected;
  final VoidCallback? onDirectionsPressed;
  final VoidCallback? onTap;

  const MuseumDiscoveryCard({
    super.key,
    required this.museum,
    this.isSelected = false,
    this.onDirectionsPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MuseumDetailScreen(museum: museum)),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 310,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.imperialGold : AppColors.parchmentBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.imperialGold.withOpacity(0.25)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Image and Category row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: AppColors.softSand,
                    child: Image.asset(
                      museum.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.museum_outlined,
                        color: AppColors.deepBurgundy,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.softSand,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              museum.category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.imperialGold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (museum.distanceKm != null) ...[
                            const Icon(Icons.near_me, size: 12, color: AppColors.deepBurgundy),
                            const SizedBox(width: 2),
                            Text(
                              museum.formattedDistance,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepBurgundy,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        museum.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalBrown,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.charcoalBrown),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    museum.location,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      minimumSize: const Size(0, 34),
                      side: const BorderSide(color: AppColors.imperialGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.alt_route, size: 13, color: AppColors.imperialGold),
                    label: const Text(
                      'Xem đường đi',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.imperialGold),
                    ),
                    onPressed: onDirectionsPressed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepBurgundy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onTap ?? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MuseumDetailScreen(museum: museum)),
                      );
                    },
                    child: const Text(
                      'Khám phá',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
