import '../core/network/api_config.dart';

typedef MuseumCategory = ({int id, String code, String name});

MuseumCategory museumCategoryFromJson(Map<String, dynamic> json) => (
  id: json['id'] as int,
  code: json['code'] as String,
  name: json['name'] as String,
);

class Museum {
  const Museum({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.openingHours,
    required this.category,
    required this.shortIntro,
    required this.googleMapsVisible,
    required this.latitude,
    required this.longitude,
    this.categories = const [],
    this.cityCode = '',
    this.distanceKm,
    this.languageCode,
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final String imageUrl;
  final String openingHours;
  final String category;
  final String shortIntro;
  final bool googleMapsVisible;
  final double? latitude;
  final double? longitude;
  final String cityCode;
  final List<MuseumCategory> categories;
  final double? distanceKm;
  final String? languageCode;

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;

  String get formattedDistance {
    if (distanceKm == null) return '';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  factory Museum.fromBackendJson(Map<String, dynamic> json) {
    return Museum(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      location: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: ApiConfig.mediaUrl(json['coverImageUrl'] as String?),
      openingHours:
          json['openingHours'] as String? ?? 'Chưa có thông tin giờ mở cửa',
      category: json['category'] as String? ?? 'Bảo tàng',
      shortIntro:
          json['shortIntro'] as String? ??
          (json['description'] as String? ?? ''),
      googleMapsVisible: json['isActive'] as bool? ?? true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      categories: (json['categories'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(museumCategoryFromJson)
          .toList(),
      cityCode: json['cityCode'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      languageCode: json['languageCode'] as String?,
    );
  }

  Museum copyWith({
    String? id,
    String? name,
    String? location,
    String? description,
    String? imageUrl,
    String? openingHours,
    String? category,
    String? shortIntro,
    bool? googleMapsVisible,
    double? latitude,
    double? longitude,
    String? cityCode,
    double? distanceKm,
    String? languageCode,
  }) {
    return Museum(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      openingHours: openingHours ?? this.openingHours,
      category: category ?? this.category,
      shortIntro: shortIntro ?? this.shortIntro,
      googleMapsVisible: googleMapsVisible ?? this.googleMapsVisible,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      categories: categories,
      cityCode: cityCode ?? this.cityCode,
      distanceKm: distanceKm ?? this.distanceKm,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
