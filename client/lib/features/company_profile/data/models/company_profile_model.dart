import '../../domain/entities/company_profile.dart';

class CompanyProfileModel {
  const CompanyProfileModel({
    required this.name,
    required this.businessType,
    required this.description,
    required this.logoObjectKey,
  });

  factory CompanyProfileModel.fromJson(Map<String, dynamic> json) {
    return CompanyProfileModel(
      name: json['name'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      logoObjectKey: json['logoObjectKey'] as String?,
    );
  }

  final String name;
  final String businessType;
  final String description;
  final String? logoObjectKey;

  CompanyProfile toEntity() {
    return CompanyProfile(
      name: name,
      businessType: businessType,
      description: description,
      logoObjectKey: logoObjectKey,
    );
  }
}
