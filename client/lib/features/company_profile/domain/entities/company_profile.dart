class CompanyProfile {
  const CompanyProfile({
    required this.name,
    required this.businessType,
    required this.description,
    required this.logoObjectKey,
  });

  final String name;
  final String businessType;
  final String description;
  final String? logoObjectKey;
}
