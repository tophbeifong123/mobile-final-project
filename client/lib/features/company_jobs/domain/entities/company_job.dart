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
  });

  final String title;
  final String description;
  final String province;
  final String workMode;
  final String category;
  final bool hasAllowance;
  final String requirements;
}

class CreatedJob {
  const CreatedJob({required this.id, required this.status});

  final String id;
  final String status;
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
