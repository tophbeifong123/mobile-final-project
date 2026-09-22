import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/job_remote_data_source.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';
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

  void apply(JobFilter filter) => state = filter;
}

final jobsControllerProvider = NotifierProvider<JobsController, JobFilter>(
  JobsController.new,
);

final jobFeedProvider = FutureProvider<List<Job>>((ref) {
  final filter = ref.watch(jobsControllerProvider);
  return ref.watch(jobRepositoryProvider).fetchFeed(filter);
});
