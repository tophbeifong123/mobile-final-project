import '../../domain/entities/job_application.dart';
import '../../domain/repositories/application_repository.dart';
import '../datasources/application_remote_data_source.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  ApplicationRepositoryImpl(this._remote);

  final ApplicationRemoteDataSource _remote;

  @override
  Future<List<JobApplication>> fetchMine() async {
    final models = await _remote.fetchMine();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<JobApplication> fetchDetail(String applicationId) async {
    return (await _remote.fetchDetail(applicationId)).toEntity();
  }

  @override
  Future<JobApplication> apply({
    required String jobId,
    required String coverLetter,
    List<String> documentIds = const [],
  }) async {
    final model = await _remote.apply(
      jobId: jobId,
      coverLetter: coverLetter,
      documentIds: documentIds,
    );
    return model.toEntity();
  }

  @override
  Future<void> completeExam(String applicationId) {
    return _remote.completeExam(applicationId);
  }
}
