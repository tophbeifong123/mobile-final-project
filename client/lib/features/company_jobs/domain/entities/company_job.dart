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

class Applicant {
  const Applicant({
    required this.applicationId,
    required this.fullName,
    required this.university,
    required this.major,
    required this.status,
    required this.coverLetter,
  });

  final String applicationId;
  final String fullName;
  final String university;
  final String major;
  final String status;
  final String coverLetter;
}
