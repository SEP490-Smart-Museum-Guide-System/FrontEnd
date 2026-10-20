class CityItem {
  final String code;
  final String name;

  const CityItem({
    required this.code,
    required this.name,
  });

  factory CityItem.fromJson(Map<String, dynamic> json) {
    return CityItem(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
  };
}
