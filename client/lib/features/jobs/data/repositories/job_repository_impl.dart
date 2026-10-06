import '../../domain/entities/job.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_remote_data_source.dart';

class JobRepositoryImpl implements JobRepository {
  JobRepositoryImpl(this._remote);

  final JobRemoteDataSource _remote;

  @override
  Future<JobPage> fetchFeed(JobFilter filter) => _remote.fetchFeed(filter);

  @override
  Future<JobDetail> fetchDetail(String jobId) async {
    final model = await _remote.fetchDetail(jobId);
    return model.toEntity();
  }

  @override
  Future<void> save(String jobId) => _remote.save(jobId);

  @override
  Future<void> unsave(String jobId) => _remote.unsave(jobId);
}
