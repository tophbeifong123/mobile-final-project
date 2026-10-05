class ThaiProvince {
  const ThaiProvince({
    required this.id,
    required this.nameTh,
    required this.centerLatitude,
    required this.centerLongitude,
    this.aliases = const [],
  });

  final int id;
  final String nameTh;
  final double centerLatitude;
  final double centerLongitude;
  final List<String> aliases;

  factory ThaiProvince.fromJson(Map<String, dynamic> json) {
    return ThaiProvince(
      id: (json['id'] as num).toInt(),
      nameTh: json['nameTh'] as String,
      centerLatitude: _coordinate(json['centerLatitude']),
      centerLongitude: _coordinate(json['centerLongitude']),
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((alias) => alias as String)
          .toList(growable: false),
    );
  }

  bool matches(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return true;
    return _normalize(nameTh).contains(normalized) ||
        aliases.any((alias) => _normalize(alias).contains(normalized));
  }

  static double _coordinate(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw const FormatException('พิกัดจังหวัดไม่ถูกต้อง');
  }

  static String _normalize(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'[\s.\-]+'), '');
}
