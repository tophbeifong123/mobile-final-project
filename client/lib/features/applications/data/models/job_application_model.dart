import '../../domain/entities/job_application.dart';

class JobApplicationModel {
  const JobApplicationModel({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.coverLetter,
    this.createdAt,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationModel(
      id: json['id'] as String,
      jobTitle: json['jobTitle'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      status: ApplicationStatus.values.byName(json['status'] as String),
      coverLetter: json['coverLetter'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  final String id;
  final String jobTitle;
  final String companyName;
  final ApplicationStatus status;
  final String coverLetter;
  final DateTime? createdAt;

  JobApplication toEntity() {
    return JobApplication(
      id: id,
      jobTitle: jobTitle,
      companyName: companyName,
      status: status,
      coverLetter: coverLetter,
      createdAt: createdAt,
    );
  }
}
