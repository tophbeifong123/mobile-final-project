import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/job_remote_data_source.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/company_logo.dart';
import '../../domain/repositories/job_repository.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepositoryImpl(JobRemoteDataSource(ref.watch(dioProvider)));
});

class JobsController extends Notifier<JobFilter> {
  @override
  JobFilter build() {
    ref.watch(jobRepositoryProvider);
    return const JobFilter();
  }

  void apply(JobFilter filter) {
    final criteriaChanged = filter.copyWith(page: 1) != state.copyWith(page: 1);
    state = criteriaChanged ? filter.copyWith(page: 1) : filter;
  }
}

final jobsControllerProvider = NotifierProvider<JobsController, JobFilter>(
  JobsController.new,
);

final jobFeedProvider = FutureProvider<JobPage>((ref) {
  final filter = ref.watch(jobsControllerProvider);
  return ref.watch(jobRepositoryProvider).fetchFeed(filter);
});

// Cards already have the availability flag; avoid fetching full job detail.
final jobCardLogoProvider = FutureProvider.autoDispose
    .family<CompanyLogo?, String>((ref, id) {
      return JobRemoteDataSource(ref.watch(dioProvider)).fetchCompanyLogo(id);
    });

final jobDetailProvider = FutureProvider.autoDispose.family<JobDetail, String>((
  ref,
  id,
) {
  return ref.watch(jobRepositoryProvider).fetchDetail(id);
});

final jobCompanyLogoProvider = FutureProvider.autoDispose
    .family<CompanyLogo?, String>((ref, id) async {
      final detail = await ref.watch(jobDetailProvider(id).future);
      if (!detail.companyLogoAvailable) return null;
      return JobRemoteDataSource(ref.watch(dioProvider)).fetchCompanyLogo(id);
    });
