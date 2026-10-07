import '../entities/company_job.dart';

abstract class CompanyJobRepository {
  Future<List<CompanyJob>> fetchMine();

  Future<EditableJob> fetchOne(String jobId);

  Future<CompanyOwnedJob> fetchOwned(String jobId);

  Future<CreatedJob> create(JobPosting posting);

  Future<EditableJob> update({
    required String jobId,
    required JobPosting posting,
    required int version,
  });

  Future<void> remove(String jobId);

  Future<void> setStatus({required String jobId, required String status});

  Future<List<Applicant>> fetchApplicants(String jobId);

  Future<Applicant> fetchApplicant({
    required String jobId,
    required String applicationId,
  });

  Future<List<int>> downloadApplicantDocument({
    required String jobId,
    required String applicationId,
    required String documentId,
  });

  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  });

  Future<void> setExamLink({
    required String jobId,
    required String applicationId,
    required String url,
    required DateTime deadline,
  });

  Future<void> passExam({
    required String jobId,
    required String applicationId,
  });

  Future<void> setInterviewLink({
    required String jobId,
    required String applicationId,
    required String url,
    required DateTime startsAt,
  });
}
