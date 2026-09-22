import '../../domain/entities/job_application.dart';

class JobApplicationModel {
  const JobApplicationModel({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.coverLetter,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationModel(
      id: json['id'] as String,
      jobTitle: json['jobTitle'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      status: ApplicationStatus.values.byName(json['status'] as String),
      coverLetter: json['coverLetter'] as String? ?? '',
    );
  }

  final String id;
  final String jobTitle;
  final String companyName;
  final ApplicationStatus status;
  final String coverLetter;

  JobApplication toEntity() {
    return JobApplication(
      id: id,
      jobTitle: jobTitle,
      companyName: companyName,
      status: status,
      coverLetter: coverLetter,
    );
  }
}
