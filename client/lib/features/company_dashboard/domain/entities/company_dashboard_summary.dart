class CompanyDashboardSummary {
  const CompanyDashboardSummary({
    required this.totalJobs,
    required this.openJobs,
    required this.totalApplicants,
    this.pendingApplicants = 0,
  });

  final int totalJobs;
  final int openJobs;
  final int totalApplicants;
  final int pendingApplicants;
}
