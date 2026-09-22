import '../entities/job_application.dart';

abstract class ApplicationRepository {
  Future<List<JobApplication>> fetchMine();

  Future<JobApplication> fetchDetail(String applicationId);

  Future<JobApplication> apply({
    required String jobId,
    required String coverLetter,
  });
}
