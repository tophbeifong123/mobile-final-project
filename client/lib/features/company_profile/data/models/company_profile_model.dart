import '../../../student_profile/data/models/student_profile_model.dart';
import '../../domain/entities/company_profile.dart';

class CompanyProfileModel {
  const CompanyProfileModel({
    required this.name,
    required this.businessType,
    required this.description,
    this.logoObjectKey,
    this.provinceId,
    this.provinceName,
    this.location = '',
    this.websiteUrl = '',
    this.contactLinks = const [],
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
      provinceId: (json['provinceId'] as num?)?.toInt(),
      provinceName: json['provinceName'] as String?,
      location: json['location'] as String? ?? '',
      websiteUrl: json['websiteUrl'] as String? ?? '',
      contactLinks: (json['contactLinks'] as List<dynamic>? ?? const [])
          .map(
            (item) => ContactLinkModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
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
      contactLinks: entity.contactLinks
          .map(ContactLinkModel.fromEntity)
          .toList(),
      location: entity.location,
      companySize: entity.companySize,
      perks: entity.perks,
      coverObjectKey: entity.coverObjectKey,
      provinceId: entity.provinceId,
      provinceName: entity.provinceName,
    );
  }

  final String name;
  final String businessType;
  final String description;
  final String? logoObjectKey;
  final int? provinceId;
  final String? provinceName;
  final String location;
  final String websiteUrl;
  final List<ContactLinkModel> contactLinks;
  final String companySize;
  final List<String> perks;
  final String? coverObjectKey;

  CompanyProfile toEntity() {
    return CompanyProfile(
      name: name,
      businessType: businessType,
      description: description,
      logoObjectKey: logoObjectKey,
      provinceId: provinceId,
      provinceName: provinceName,
      location: location,
      websiteUrl: websiteUrl,
      contactLinks: contactLinks.map((link) => link.toEntity()).toList(),
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
      'provinceId': provinceId,
      'location': location,
      'websiteUrl': websiteUrl,
      'contactLinks': contactLinks.map((link) => link.toJson()).toList(),
      'companySize': companySize,
      'perks': perks,
    };
  }
}
