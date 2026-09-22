import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/company_dashboard_remote_data_source.dart';
import '../../data/repositories/company_dashboard_repository_impl.dart';
import '../../domain/repositories/company_dashboard_repository.dart';

final companyDashboardRepositoryProvider = Provider<CompanyDashboardRepository>(
  (ref) {
    return CompanyDashboardRepositoryImpl(
      CompanyDashboardRemoteDataSource(ref.watch(dioProvider)),
    );
  },
);

class CompanyDashboardController extends Notifier<void> {
  @override
  void build() {
    ref.watch(companyDashboardRepositoryProvider);
  }
}

final companyDashboardControllerProvider =
    NotifierProvider<CompanyDashboardController, void>(
      CompanyDashboardController.new,
    );
