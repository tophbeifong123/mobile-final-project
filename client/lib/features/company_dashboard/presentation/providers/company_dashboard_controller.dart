import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/company_dashboard_remote_data_source.dart';
import '../../data/repositories/company_dashboard_repository_impl.dart';
import '../../domain/entities/company_dashboard_summary.dart';
import '../../domain/repositories/company_dashboard_repository.dart';

final companyDashboardRepositoryProvider = Provider<CompanyDashboardRepository>(
  (ref) {
    return CompanyDashboardRepositoryImpl(
      CompanyDashboardRemoteDataSource(ref.watch(dioProvider)),
    );
  },
);

final companyDashboardSummaryProvider = FutureProvider<CompanyDashboardSummary>(
  (ref) {
    return ref.watch(companyDashboardRepositoryProvider).fetchSummary();
  },
);

class CompanyDashboardController extends Notifier<void> {
  @override
  void build() {
    ref.watch(companyDashboardRepositoryProvider);
  }

  void refresh() {
    ref.invalidate(companyDashboardSummaryProvider);
  }
}

final companyDashboardControllerProvider =
    NotifierProvider<CompanyDashboardController, void>(
      CompanyDashboardController.new,
    );
