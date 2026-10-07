import '../../domain/entities/company_job.dart';
import 'package:client/features/student_profile/data/models/student_profile_model.dart';

class CompanyJobModel {
  const CompanyJobModel({
    required this.id,
    required this.title,
    required this.status,
    required this.workMode,
    this.interviewMode = 'online',
    required this.applicantCount,
    required this.pendingApplicantCount,
    this.deadline,
  });

  factory CompanyJobModel.fromJson(Map<String, dynamic> json) {
    return CompanyJobModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      workMode: json['workMode'] as String? ?? 'hybrid',
      interviewMode: json['interviewMode'] as String? ?? 'online',
      applicantCount: json['applicantCount'] as int? ?? 0,
      pendingApplicantCount: json['pendingApplicantCount'] as int? ?? 0,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
    );
  }

  final String id;
  final String title;
  final String status;
  final String workMode;
  final String interviewMode;
  final int applicantCount;
  final int pendingApplicantCount;
  final DateTime? deadline;

  CompanyJob toEntity() {
    return CompanyJob(
      id: id,
      title: title,
      status: status,
      workMode: workMode,
      interviewMode: interviewMode,
      applicantCount: applicantCount,
      pendingApplicantCount: pendingApplicantCount,
      deadline: deadline,
    );
  }
}

class CompanyOwnedJobModel {
  const CompanyOwnedJobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.province,
    required this.workMode,
    this.interviewMode = 'online',
    required this.category,
    required this.hasAllowance,
    this.openings,
    this.allowanceAmount,
    required this.requirements,
    required this.status,
    required this.version,
    required this.applicantCount,
    required this.pendingApplicantCount,
    this.skills = const [],
    this.deadline,
  });

  factory CompanyOwnedJobModel.fromJson(Map<String, dynamic> json) {
    return CompanyOwnedJobModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      province: json['province'] as String? ?? '',
      workMode: json['workMode'] as String? ?? 'hybrid',
      interviewMode: json['interviewMode'] as String? ?? 'online',
      category: json['category'] as String? ?? '',
      hasAllowance: json['hasAllowance'] as bool? ?? false,
      openings: json['openings'] as int?,
      allowanceAmount: json['allowanceAmount'] as int?,
      requirements: json['requirements'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      version: json['version'] as int? ?? 1,
      applicantCount: json['applicantCount'] as int? ?? 0,
      pendingApplicantCount: json['pendingApplicantCount'] as int? ?? 0,
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((skill) => skill.toString())
              .toList() ??
          const [],
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
    );
  }

  final String id;
  final String title;
  final String description;
  final String province;
  final String workMode;
  final String interviewMode;
  final String category;
  final bool hasAllowance;
  final int? openings;
  final int? allowanceAmount;
  final String requirements;
  final String status;
  final int version;
  final int applicantCount;
  final int pendingApplicantCount;
  final List<String> skills;
  final DateTime? deadline;

  CompanyOwnedJob toEntity() {
    return CompanyOwnedJob(
      id: id,
      title: title,
      description: description,
      province: province,
      workMode: workMode,
      interviewMode: interviewMode,
      category: category,
      hasAllowance: hasAllowance,
      openings: openings,
      allowanceAmount: allowanceAmount,
      requirements: requirements,
      status: status,
      version: version,
      applicantCount: applicantCount,
      pendingApplicantCount: pendingApplicantCount,
      skills: skills,
      deadline: deadline,
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
    this.interviewMode = 'online',
    required this.category,
    required this.hasAllowance,
    this.openings,
    this.allowanceAmount,
    required this.requirements,
    required this.status,
    required this.version,
    this.skills = const [],
  });

  factory EditableJobModel.fromJson(Map<String, dynamic> json) {
    return EditableJobModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      province: json['province'] as String? ?? '',
      workMode: json['workMode'] as String? ?? 'hybrid',
      interviewMode: json['interviewMode'] as String? ?? 'online',
      category: json['category'] as String? ?? '',
      hasAllowance: json['hasAllowance'] as bool? ?? false,
      openings: json['openings'] as int?,
      allowanceAmount: json['allowanceAmount'] as int?,
      requirements: json['requirements'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      version: json['version'] as int? ?? 1,
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  final String id;
  final String title;
  final String description;
  final String province;
  final String workMode;
  final String interviewMode;
  final String category;
  final bool hasAllowance;
  final int? openings;
  final int? allowanceAmount;
  final String requirements;
  final String status;
  final int version;
  final List<String> skills;

  EditableJob toEntity() {
    return EditableJob(
      id: id,
      title: title,
      description: description,
      province: province,
      workMode: workMode,
      interviewMode: interviewMode,
      category: category,
      hasAllowance: hasAllowance,
      openings: openings,
      allowanceAmount: allowanceAmount,
      requirements: requirements,
      status: status,
      version: version,
      skills: skills,
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
    this.bio = '',
    this.contactLinks = const [],
    this.portfolioLinks = const [],
    this.portfolioUrl,
    this.resumeObjectKey,
    this.resumeFileName,
    this.avatarObjectKey,
    this.createdAt,
    this.documents = const [],
    this.examUrl,
    this.examDeadline,
    this.examCompletedAt,
    this.examPassedAt,
    this.interviewUrl,
    this.interviewStartsAt,
    this.interviewMode = 'online',
  });

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    return ApplicantModel(
      applicationId: (json['applicationId'] ?? json['id']) as String,
      fullName: json['fullName'] as String? ?? '',
      university: json['university'] as String? ?? '',
      major: json['major'] as String? ?? '',
      status: json['status'] as String? ?? 'submitted',
      coverLetter: json['coverLetter'] as String? ?? '',
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bio: json['bio'] as String? ?? '',
      contactLinks: (json['contactLinks'] as List<dynamic>? ?? const [])
          .map(
            (item) => ContactLinkModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      portfolioLinks: (json['portfolioLinks'] as List<dynamic>? ?? const [])
          .map(
            (item) => PortfolioLinkModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      portfolioUrl: json['portfolioUrl'] as String?,
      resumeObjectKey: json['resumeObjectKey'] as String?,
      resumeFileName: json['resumeFileName'] as String?,
      avatarObjectKey: json['avatarObjectKey'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      documents: (json['documents'] as List<dynamic>? ?? const []).map((item) {
        final document = item as Map<String, dynamic>;
        return ApplicantDocumentModel(
          id: document['id'] as String,
          type: document['type'] as String,
          fileName: document['fileName'] as String,
        );
      }).toList(),
      examUrl: json['examUrl'] as String?,
      examDeadline: _parseSelectionDate(json['examDeadline']),
      examCompletedAt: _parseSelectionDate(json['examCompletedAt']),
      examPassedAt: _parseSelectionDate(json['examPassedAt']),
      interviewUrl: json['interviewUrl'] as String?,
      interviewStartsAt: _parseSelectionDate(json['interviewStartsAt']),
      interviewMode: json['interviewMode'] as String? ?? 'online',
    );
  }

  final String applicationId;
  final String fullName;
  final String university;
  final String major;
  final String status;
  final String coverLetter;
  final List<String> skills;
  final String bio;
  final List<ContactLinkModel> contactLinks;
  final List<PortfolioLinkModel> portfolioLinks;
  final String? portfolioUrl;
  final String? resumeObjectKey;
  final String? resumeFileName;
  final String? avatarObjectKey;
  final DateTime? createdAt;
  final List<ApplicantDocumentModel> documents;
  final String? examUrl;
  final DateTime? examDeadline;
  final DateTime? examCompletedAt;
  final DateTime? examPassedAt;
  final String? interviewUrl;
  final DateTime? interviewStartsAt;
  final String interviewMode;

  Applicant toEntity() {
    return Applicant(
      applicationId: applicationId,
      fullName: fullName,
      university: university,
      major: major,
      status: status,
      coverLetter: coverLetter,
      skills: skills,
      bio: bio,
      contactLinks: contactLinks.map((c) => c.toEntity()).toList(),
      portfolioLinks: portfolioLinks.map((p) => p.toEntity()).toList(),
      portfolioUrl: portfolioUrl,
      resumeObjectKey: resumeObjectKey,
      resumeFileName: resumeFileName,
      avatarObjectKey: avatarObjectKey,
      createdAt: createdAt,
      documents: documents
          .map(
            (d) =>
                ApplicantDocument(id: d.id, type: d.type, fileName: d.fileName),
          )
          .toList(),
      examUrl: examUrl,
      examDeadline: examDeadline,
      examCompletedAt: examCompletedAt,
      examPassedAt: examPassedAt,
      interviewUrl: interviewUrl,
      interviewStartsAt: interviewStartsAt,
      interviewMode: interviewMode,
    );
  }
}

DateTime? _parseSelectionDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

class ApplicantDocumentModel {
  const ApplicantDocumentModel({
    required this.id,
    required this.type,
    required this.fileName,
  });
  final String id;
  final String type;
  final String fileName;
}
