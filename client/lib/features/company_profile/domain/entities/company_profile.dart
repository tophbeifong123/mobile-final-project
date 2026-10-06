class CompanyProfile {
  const CompanyProfile({
    required this.name,
    required this.businessType,
    required this.description,
    this.logoObjectKey,
    this.provinceId,
    this.provinceName,
    this.location = '',
    this.websiteUrl = '',
    this.companySize = '',
    this.perks = const [],
    this.coverObjectKey,
  });

  final String name;
  final String businessType;
  final String description;
  final String? logoObjectKey;
  final int? provinceId;
  final String? provinceName;
  final String location;
  final String websiteUrl;
  final String companySize;
  final List<String> perks;
  final String? coverObjectKey;

  CompanyProfile copyWith({
    String? name,
    String? businessType,
    String? description,
    String? Function()? logoObjectKey,
    String? websiteUrl,
    String? location,
    int? Function()? provinceId,
    String? Function()? provinceName,
    String? companySize,
    List<String>? perks,
    String? Function()? coverObjectKey,
  }) {
    return CompanyProfile(
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      description: description ?? this.description,
      logoObjectKey: logoObjectKey != null
          ? logoObjectKey()
          : this.logoObjectKey,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      location: location ?? this.location,
      provinceId: provinceId != null ? provinceId() : this.provinceId,
      provinceName: provinceName != null ? provinceName() : this.provinceName,
      companySize: companySize ?? this.companySize,
      perks: perks ?? this.perks,
      coverObjectKey: coverObjectKey != null
          ? coverObjectKey()
          : this.coverObjectKey,
    );
  }
}
