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
}
