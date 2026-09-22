enum ApplicationStatus { submitted, reviewing, accepted, rejected }

class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.coverLetter,
  });

  final String id;
  final String jobTitle;
  final String companyName;
  final ApplicationStatus status;
  final String coverLetter;
}
