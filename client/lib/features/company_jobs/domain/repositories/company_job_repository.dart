import '../entities/company_job.dart';

abstract class CompanyJobRepository {
  Future<List<CompanyJob>> fetchMine();

  Future<void> setStatus({required String jobId, required String status});

  Future<List<Applicant>> fetchApplicants(String jobId);

  Future<Applicant> fetchApplicant({
    required String jobId,
    required String applicationId,
  });

  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  });
}
