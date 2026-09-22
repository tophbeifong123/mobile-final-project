enum WorkMode { onSite, hybrid, remote }

enum JobStatus { open, closed }

class JobFilter {
  const JobFilter({
    this.search = '',
    this.province,
    this.workMode,
    this.category,
    this.hasAllowance,
  });

  final String search;
  final String? province;
  final WorkMode? workMode;
  final String? category;
  final bool? hasAllowance;
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.companyName,
    required this.province,
    required this.workMode,
    required this.category,
    required this.hasAllowance,
    required this.status,
  });

  final String id;
  final String title;
  final String companyName;
  final String province;
  final WorkMode workMode;
  final String category;
  final bool hasAllowance;
  final JobStatus status;
}
