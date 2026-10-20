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
    this.cityCode = '',
    this.distanceKm,
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
  final double latitude;
  final double longitude;
  final String cityCode;
  final double? distanceKm;

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
      imageUrl: json['coverImageUrl'] as String? ?? 'assets/images/national-museum-web.jpg',
      openingHours: json['openingHours'] as String? ?? '08:00 - 17:00',
      category: json['category'] as String? ?? 'Lịch sử & Di sản',
      shortIntro: json['shortIntro'] as String? ?? (json['description'] as String? ?? ''),
      googleMapsVisible: json['isActive'] as bool? ?? true,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      cityCode: json['cityCode'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
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
      cityCode: cityCode ?? this.cityCode,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
