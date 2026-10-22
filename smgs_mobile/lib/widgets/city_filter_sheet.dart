import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/city.dart';

class CityFilterSheet extends StatelessWidget {
  final List<CityItem> cities;
  final String? selectedCityCode;
  final ValueChanged<CityItem?> onCitySelected;

  const CityFilterSheet({
    super.key,
    required this.cities,
    required this.selectedCityCode,
    required this.onCitySelected,
  });

  static Future<CityItem?> show(
    BuildContext context, {
    required List<CityItem> cities,
    required String? selectedCityCode,
  }) {
    return showModalBottomSheet<CityItem>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CityFilterSheet(
        cities: cities,
        selectedCityCode: selectedCityCode,
        onCitySelected: (city) => Navigator.of(ctx).pop(city),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.antiqueIvory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.charcoalBrown.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LỌC THEO TỈNH / THÀNH PHỐ',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.imperialGold,
                        letterSpacing: 1.2,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Địa hạt Di sản & Bảo tàng',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.deepBurgundy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.charcoalBrown),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.parchmentBorder),

          // All cities option
          ListTile(
            leading: Icon(
              Icons.public,
              color: selectedCityCode == null || selectedCityCode!.isEmpty
                  ? AppColors.deepBurgundy
                  : AppColors.charcoalBrown,
            ),
            title: Text(
              'Tất cả địa hạt (Toàn quốc)',
              style: TextStyle(
                fontWeight: selectedCityCode == null || selectedCityCode!.isEmpty
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: selectedCityCode == null || selectedCityCode!.isEmpty
                    ? AppColors.deepBurgundy
                    : AppColors.charcoalBrown,
              ),
            ),
            trailing: selectedCityCode == null || selectedCityCode!.isEmpty
                ? const Icon(Icons.check, color: AppColors.deepBurgundy)
                : null,
            onTap: () => onCitySelected(null),
          ),
          const Divider(height: 1, color: AppColors.parchmentBorder),

          // List of cities
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: cities.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 64,
                color: AppColors.parchmentBorder,
              ),
              itemBuilder: (context, index) {
                final city = cities[index];
                final isSelected = selectedCityCode == city.code;
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.deepBurgundy : AppColors.softSand,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.deepBurgundy : AppColors.parchmentBorder,
                      ),
                    ),
                    child: Text(
                      city.code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.charcoalBrown,
                      ),
                    ),
                  ),
                  title: Text(
                    city.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.deepBurgundy : AppColors.charcoalBrown,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.deepBurgundy)
                      : null,
                  onTap: () => onCitySelected(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
