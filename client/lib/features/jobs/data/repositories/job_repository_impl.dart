import '../../domain/entities/job.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_remote_data_source.dart';

class JobRepositoryImpl implements JobRepository {
  JobRepositoryImpl(this._remote);

  final JobRemoteDataSource _remote;

  @override
  Future<List<Job>> fetchFeed(JobFilter filter) async {
    final models = await _remote.fetchFeed(filter);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Job> fetchDetail(String jobId) async {
    final model = await _remote.fetchDetail(jobId);
    return model.toEntity();
  }

  @override
  Future<void> save(String jobId) => _remote.save(jobId);

  @override
  Future<void> unsave(String jobId) => _remote.unsave(jobId);
}
