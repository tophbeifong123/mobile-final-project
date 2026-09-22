import '../entities/company_dashboard_summary.dart';

abstract class CompanyDashboardRepository {
  Future<CompanyDashboardSummary> fetchSummary();
}
