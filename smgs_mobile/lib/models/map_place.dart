class MapPlace {
  const MapPlace(this.name, this.address, this.latitude, this.longitude);
  final String name, address;
  final double latitude, longitude;

  factory MapPlace.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num).toDouble();
    final lon = (json['longitude'] as num).toDouble();
    final name = json['name'] as String;
    if (name.trim().isEmpty ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      throw const FormatException('Địa điểm trả về không hợp lệ.');
    }
    return MapPlace(name, json['address'] as String, lat, lon);
  }
}
