import '../entities/job.dart';

abstract class JobRepository {
  Future<List<Job>> fetchFeed(JobFilter filter);

  Future<Job> fetchDetail(String jobId);

  Future<void> save(String jobId);

  Future<void> unsave(String jobId);
}
