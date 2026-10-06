import '../../domain/entities/company_dashboard_summary.dart';

class CompanyDashboardSummaryModel {
  const CompanyDashboardSummaryModel({
    required this.totalJobs,
    required this.openJobs,
    required this.totalApplicants,
    this.pendingApplicants = 0,
  });

  factory CompanyDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return CompanyDashboardSummaryModel(
      totalJobs: json['totalJobs'] as int? ?? 0,
      openJobs: json['openJobs'] as int? ?? 0,
      totalApplicants: json['totalApplicants'] as int? ?? 0,
      pendingApplicants: json['pendingApplicants'] as int? ?? 0,
    );
  }

  final int totalJobs;
  final int openJobs;
  final int totalApplicants;
  final int pendingApplicants;

  CompanyDashboardSummary toEntity() {
    return CompanyDashboardSummary(
      totalJobs: totalJobs,
      openJobs: openJobs,
      totalApplicants: totalApplicants,
      pendingApplicants: pendingApplicants,
    );
  }
}
