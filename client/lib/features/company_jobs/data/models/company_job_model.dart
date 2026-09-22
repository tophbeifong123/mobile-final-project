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

class ApplicantModel {
  const ApplicantModel({
    required this.applicationId,
    required this.fullName,
    required this.university,
    required this.major,
    required this.status,
    required this.coverLetter,
  });

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    return ApplicantModel(
      applicationId: json['applicationId'] as String,
      fullName: json['fullName'] as String? ?? '',
      university: json['university'] as String? ?? '',
      major: json['major'] as String? ?? '',
      status: json['status'] as String? ?? 'submitted',
      coverLetter: json['coverLetter'] as String? ?? '',
    );
  }

  final String applicationId;
  final String fullName;
  final String university;
  final String major;
  final String status;
  final String coverLetter;

  Applicant toEntity() {
    return Applicant(
      applicationId: applicationId,
      fullName: fullName,
      university: university,
      major: major,
      status: status,
      coverLetter: coverLetter,
    );
  }
}
