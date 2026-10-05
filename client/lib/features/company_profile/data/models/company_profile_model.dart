import '../../domain/entities/company_profile.dart';

class CompanyProfileModel {
  const CompanyProfileModel({
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

  factory CompanyProfileModel.fromJson(Map<String, dynamic> json) {
    return CompanyProfileModel(
      name: json['name'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      logoObjectKey: json['logoObjectKey'] as String?,
      provinceId: (json['provinceId'] as num?)?.toInt(),
      provinceName: json['provinceName'] as String?,
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  final String name;
  final String businessType;
  final String description;
  final String? logoObjectKey;
  final int? provinceId;
  final String? provinceName;
  final String location;
  final double? latitude;
  final double? longitude;

  CompanyProfile toEntity() {
    return CompanyProfile(
      name: name,
      businessType: businessType,
      description: description,
      logoObjectKey: logoObjectKey,
      provinceId: provinceId,
      provinceName: provinceName,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'businessType': businessType,
      'description': description,
      'provinceId': provinceId,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
