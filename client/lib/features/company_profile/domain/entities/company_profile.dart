class CompanyProfile {
  const CompanyProfile({
    required this.name,
    required this.businessType,
    required this.description,
    required this.logoObjectKey,
    this.provinceId,
    this.provinceName,
    this.location = '',
    this.latitude,
    this.longitude,
  });

  final String name;
  final String businessType;
  final String description;
  final String? logoObjectKey;
  final int? provinceId;
  final String? provinceName;
  final String location;
  final double? latitude;
  final double? longitude;
}
