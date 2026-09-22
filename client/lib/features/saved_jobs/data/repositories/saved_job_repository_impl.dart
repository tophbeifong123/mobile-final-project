import '../../domain/entities/saved_job.dart';
import '../../domain/repositories/saved_job_repository.dart';
import '../datasources/saved_job_remote_data_source.dart';

class SavedJobRepositoryImpl implements SavedJobRepository {
  SavedJobRepositoryImpl(this._remote);

  final SavedJobRemoteDataSource _remote;

  @override
  Future<List<SavedJob>> fetchSaved() async {
    final models = await _remote.fetchSaved();
    return models.map((model) => model.toEntity()).toList();
  }
}
