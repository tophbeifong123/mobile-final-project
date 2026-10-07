import '../entities/job.dart';

abstract class JobRepository {
  Future<JobPage> fetchFeed(JobFilter filter);

  Future<JobDetail> fetchDetail(String jobId);

  Future<void> save(String jobId);

  Future<void> unsave(String jobId);
}
