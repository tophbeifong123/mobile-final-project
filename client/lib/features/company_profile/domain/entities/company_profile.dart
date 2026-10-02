class CompanyProfile {
  const CompanyProfile({
    required this.name,
    required this.businessType,
    required this.description,
    this.logoObjectKey,
    this.websiteUrl = '',
    this.location = '',
    this.companySize = '',
    this.perks = const [],
    this.coverObjectKey,
  });

  final String name;
  final String businessType;
  final String description;
  final String? logoObjectKey;
  final String websiteUrl;
  final String location;
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
      companySize: companySize ?? this.companySize,
      perks: perks ?? this.perks,
      coverObjectKey: coverObjectKey != null
          ? coverObjectKey()
          : this.coverObjectKey,
    );
  }
}
