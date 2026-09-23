import '../../domain/entities/company_job.dart';

class CompanyJobModel {
  const CompanyJobModel({
    required this.id,
    required this.title,
    required this.status,
    required this.applicantCount,
  });

  factory CompanyJobModel.fromJson(Map<String, dynamic> json) {
    return CompanyJobModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      applicantCount: json['applicantCount'] as int? ?? 0,
    );
  }

  final String id;
  final String title;
  final String status;
  final int applicantCount;

  CompanyJob toEntity() {
    return CompanyJob(
      id: id,
      title: title,
      status: status,
      applicantCount: applicantCount,
    );
  }
}

class CreatedJobModel {
  const CreatedJobModel({required this.id, required this.status});

  factory CreatedJobModel.fromJson(Map<String, dynamic> json) {
    return CreatedJobModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'open',
    );
  }

  final String id;
  final String status;

  CreatedJob toEntity() {
    return CreatedJob(id: id, status: status);
  }
}

class EditableJobModel {
  const EditableJobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.province,
    required this.workMode,
    required this.category,
    required this.hasAllowance,
    required this.requirements,
    required this.status,
    required this.version,
  });

  factory EditableJobModel.fromJson(Map<String, dynamic> json) {
    return EditableJobModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      province: json['province'] as String? ?? '',
      workMode: json['workMode'] as String? ?? 'hybrid',
      category: json['category'] as String? ?? '',
      hasAllowance: json['hasAllowance'] as bool? ?? false,
      requirements: json['requirements'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      version: json['version'] as int? ?? 1,
    );
  }

  final String id;
  final String title;
  final String description;
  final String province;
  final String workMode;
  final String category;
  final bool hasAllowance;
  final String requirements;
  final String status;
  final int version;

  EditableJob toEntity() {
    return EditableJob(
      id: id,
      title: title,
      description: description,
      province: province,
      workMode: workMode,
      category: category,
      hasAllowance: hasAllowance,
      requirements: requirements,
      status: status,
      version: version,
    );
  }
}

class ApplicantModel {
  const ApplicantModel({
    required this.applicationId,
    required this.fullName,
    required this.university,
    required this.major,
    required this.status,
    required this.coverLetter,
    this.skills = const [],
    this.portfolioUrl,
    this.resumeObjectKey,
    this.resumeFileName,
    this.createdAt,
  });

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    return ApplicantModel(
      applicationId: (json['applicationId'] ?? json['id']) as String,
      fullName: json['fullName'] as String? ?? '',
      university: json['university'] as String? ?? '',
      major: json['major'] as String? ?? '',
      status: json['status'] as String? ?? 'submitted',
      coverLetter: json['coverLetter'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      portfolioUrl: json['portfolioUrl'] as String?,
      resumeObjectKey: json['resumeObjectKey'] as String?,
      resumeFileName: json['resumeFileName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  final String applicationId;
  final String fullName;
  final String university;
  final String major;
  final String status;
  final String coverLetter;
  final List<String> skills;
  final String? portfolioUrl;
  final String? resumeObjectKey;
  final String? resumeFileName;
  final DateTime? createdAt;

  Applicant toEntity() {
    return Applicant(
      applicationId: applicationId,
      fullName: fullName,
      university: university,
      major: major,
      status: status,
      coverLetter: coverLetter,
      skills: skills,
      portfolioUrl: portfolioUrl,
      resumeObjectKey: resumeObjectKey,
      resumeFileName: resumeFileName,
      createdAt: createdAt,
    );
  }
}
