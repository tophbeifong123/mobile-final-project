import '../../domain/entities/company_job.dart';
import '../../domain/repositories/company_job_repository.dart';
import '../datasources/company_job_remote_data_source.dart';

class CompanyJobRepositoryImpl implements CompanyJobRepository {
  CompanyJobRepositoryImpl(this._remote);

  final CompanyJobRemoteDataSource _remote;

  @override
  Future<List<CompanyJob>> fetchMine() async {
    final models = await _remote.fetchMine();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> setStatus({required String jobId, required String status}) {
    return _remote.setStatus(jobId: jobId, status: status);
  }

  @override
  Future<List<Applicant>> fetchApplicants(String jobId) async {
    final models = await _remote.fetchApplicants(jobId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Applicant> fetchApplicant({
    required String jobId,
    required String applicationId,
  }) async {
    final model = await _remote.fetchApplicant(
      jobId: jobId,
      applicationId: applicationId,
    );
    return model.toEntity();
  }

  @override
  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  }) {
    return _remote.updateApplicantStatus(
      jobId: jobId,
      applicationId: applicationId,
      status: status,
    );
  }
}
