import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/company_job_remote_data_source.dart';
import '../../data/repositories/company_job_repository_impl.dart';
import '../../domain/repositories/company_job_repository.dart';

final companyJobRepositoryProvider = Provider<CompanyJobRepository>((ref) {
  return CompanyJobRepositoryImpl(
    CompanyJobRemoteDataSource(ref.watch(dioProvider)),
  );
});

class CompanyJobsController extends Notifier<void> {
  @override
  void build() {
    ref.watch(companyJobRepositoryProvider);
  }
}

final companyJobsControllerProvider =
    NotifierProvider<CompanyJobsController, void>(CompanyJobsController.new);
