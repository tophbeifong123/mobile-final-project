class ThaiProvince {
  const ThaiProvince({
    required this.id,
    required this.nameTh,
    this.aliases = const [],
  });

  final int id;
  final String nameTh;
  final List<String> aliases;

  factory ThaiProvince.fromJson(Map<String, dynamic> json) {
    return ThaiProvince(
      id: (json['id'] as num).toInt(),
      nameTh: json['nameTh'] as String,
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

  static String _normalize(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'[\s.\-]+'), '');
}
