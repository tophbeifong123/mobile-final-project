import '../../domain/entities/company_profile.dart';

class CompanyProfileModel {
  const CompanyProfileModel({
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

  factory CompanyProfileModel.fromJson(Map<String, dynamic> json) {
    return CompanyProfileModel(
      name: json['name'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      logoObjectKey: json['logoObjectKey'] as String?,
      websiteUrl: json['websiteUrl'] as String? ?? '',
      location: json['location'] as String? ?? '',
      companySize: json['companySize'] as String? ?? '',
      perks:
          (json['perks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      coverObjectKey: json['coverObjectKey'] as String?,
    );
  }

  factory CompanyProfileModel.fromEntity(CompanyProfile entity) {
    return CompanyProfileModel(
      name: entity.name,
      businessType: entity.businessType,
      description: entity.description,
      logoObjectKey: entity.logoObjectKey,
      websiteUrl: entity.websiteUrl,
      location: entity.location,
      companySize: entity.companySize,
      perks: entity.perks,
      coverObjectKey: entity.coverObjectKey,
    );
  }

  final String name;
  final String businessType;
  final String description;
  final String? logoObjectKey;
  final String websiteUrl;
  final String location;
  final String companySize;
  final List<String> perks;
  final String? coverObjectKey;

  CompanyProfile toEntity() {
    return CompanyProfile(
      name: name,
      businessType: businessType,
      description: description,
      logoObjectKey: logoObjectKey,
      websiteUrl: websiteUrl,
      location: location,
      companySize: companySize,
      perks: perks,
      coverObjectKey: coverObjectKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'businessType': businessType,
      'description': description,
      'websiteUrl': websiteUrl,
      'location': location,
      'companySize': companySize,
      'perks': perks,
    };
  }
}
