import '../../domain/entities/company_dashboard_summary.dart';
import '../../domain/repositories/company_dashboard_repository.dart';
import '../datasources/company_dashboard_remote_data_source.dart';

class CompanyDashboardRepositoryImpl implements CompanyDashboardRepository {
  CompanyDashboardRepositoryImpl(this._remote);

  final CompanyDashboardRemoteDataSource _remote;

  @override
  Future<CompanyDashboardSummary> fetchSummary() async {
    return (await _remote.fetchSummary()).toEntity();
  }
}
