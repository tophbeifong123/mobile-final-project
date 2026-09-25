import 'package:client/features/student_profile/domain/entities/student_profile.dart';

class CompanyJob {
  const CompanyJob({
    required this.id,
    required this.title,
    required this.status,
    required this.applicantCount,
  });

  final String id;
  final String title;
  final String status;
  final int applicantCount;
}

class JobPosting {
  const JobPosting({
    required this.title,
    required this.description,
    required this.province,
    required this.workMode,
    required this.category,
    required this.hasAllowance,
    required this.requirements,
    this.skills = const [],
  });

  final String title;
  final String description;
  final String province;
  final String workMode;
  final String category;
  final bool hasAllowance;
  final String requirements;
  final List<String> skills;
}

class CreatedJob {
  const CreatedJob({required this.id, required this.status});

  final String id;
  final String status;
}

class EditableJob {
  const EditableJob({
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
    this.skills = const [],
  });

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
  final List<String> skills;
}

class Applicant {
  const Applicant({
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
    this.createdAt,
  });

  final String applicationId;
  final String fullName;
  final String university;
  final String major;
  final String status;
  final String coverLetter;
  final List<String> skills;
  final String bio;
  final List<ContactLink> contactLinks;
  final List<PortfolioLink> portfolioLinks;
  final String? portfolioUrl;
  final String? resumeObjectKey;
  final String? resumeFileName;
  final DateTime? createdAt;
}
