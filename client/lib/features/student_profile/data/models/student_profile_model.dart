import '../../domain/entities/student_profile.dart';

class ContactLinkModel {
  const ContactLinkModel({
    this.id,
    required this.platform,
    this.label,
    required this.value,
  });

  factory ContactLinkModel.fromJson(Map<String, dynamic> json) {
    return ContactLinkModel(
      id: json['id'] as String?,
      platform: json['platform'] as String? ?? 'other',
      label: json['label'] as String?,
      value: json['value'] as String? ?? '',
    );
  }

  factory ContactLinkModel.fromEntity(ContactLink entity) {
    return ContactLinkModel(
      id: entity.id,
      platform: entity.platform,
      label: entity.label,
      value: entity.value,
    );
  }

  final String? id;
  final String platform;
  final String? label;
  final String value;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'platform': platform,
      if (label != null && label!.isNotEmpty) 'label': label,
      'value': value,
    };
  }

  ContactLink toEntity() {
    return ContactLink(
      id: id,
      platform: platform,
      label: label,
      value: value,
    );
  }
}

class PortfolioLinkModel {
  const PortfolioLinkModel({
    this.id,
    required this.title,
    required this.url,
    this.description,
  });

  factory PortfolioLinkModel.fromJson(Map<String, dynamic> json) {
    return PortfolioLinkModel(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  factory PortfolioLinkModel.fromEntity(PortfolioLink entity) {
    return PortfolioLinkModel(
      id: entity.id,
      title: entity.title,
      url: entity.url,
      description: entity.description,
    );
  }

  final String? id;
  final String title;
  final String url;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'url': url,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }

  PortfolioLink toEntity() {
    return PortfolioLink(
      id: id,
      title: title,
      url: url,
      description: description,
    );
  }
}

class StudentProfileModel {
  const StudentProfileModel({
    required this.fullName,
    required this.university,
    required this.major,
    required this.skills,
    this.bio = '',
    this.contactLinks = const [],
    this.portfolioLinks = const [],
    required this.portfolioUrl,
    this.resumeFileName,
    this.resumeObjectKey,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      fullName: json['fullName'] as String? ?? '',
      university: json['university'] as String? ?? '',
      major: json['major'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>? ?? const [])
          .map((skill) => skill as String)
          .toList(),
      bio: json['bio'] as String? ?? '',
      contactLinks: (json['contactLinks'] as List<dynamic>? ?? const [])
          .map((item) =>
              ContactLinkModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      portfolioLinks: (json['portfolioLinks'] as List<dynamic>? ?? const [])
          .map((item) =>
              PortfolioLinkModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      portfolioUrl: json['portfolioUrl'] as String?,
      resumeFileName: json['resumeFileName'] as String?,
      resumeObjectKey: json['resumeObjectKey'] as String?,
    );
  }

  factory StudentProfileModel.fromEntity(StudentProfile entity) {
    return StudentProfileModel(
      fullName: entity.fullName,
      university: entity.university,
      major: entity.major,
      skills: entity.skills,
      bio: entity.bio,
      contactLinks: entity.contactLinks
          .map((c) => ContactLinkModel.fromEntity(c))
          .toList(),
      portfolioLinks: entity.portfolioLinks
          .map((p) => PortfolioLinkModel.fromEntity(p))
          .toList(),
      portfolioUrl: entity.portfolioUrl,
      resumeFileName: entity.resumeFileName,
      resumeObjectKey: entity.resumeObjectKey,
    );
  }

  final String fullName;
  final String university;
  final String major;
  final List<String> skills;
  final String bio;
  final List<ContactLinkModel> contactLinks;
  final List<PortfolioLinkModel> portfolioLinks;
  final String? portfolioUrl;
  final String? resumeFileName;
  final String? resumeObjectKey;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'university': university,
      'major': major,
      'skills': skills,
      'bio': bio,
      'contactLinks': contactLinks.map((c) => c.toJson()).toList(),
      'portfolioLinks': portfolioLinks.map((p) => p.toJson()).toList(),
      'portfolioUrl': portfolioUrl,
    };
  }

  StudentProfile toEntity() {
    return StudentProfile(
      fullName: fullName,
      university: university,
      major: major,
      skills: skills,
      bio: bio,
      contactLinks: contactLinks.map((c) => c.toEntity()).toList(),
      portfolioLinks: portfolioLinks.map((p) => p.toEntity()).toList(),
      portfolioUrl: portfolioUrl,
      resumeFileName: resumeFileName,
      resumeObjectKey: resumeObjectKey,
    );
  }
}
