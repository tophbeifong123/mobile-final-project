import '../../domain/entities/resume_file.dart';
import '../../domain/repositories/resume_repository.dart';
import '../datasources/resume_remote_data_source.dart';

class ResumeRepositoryImpl implements ResumeRepository {
  ResumeRepositoryImpl(this._remote);

  final ResumeRemoteDataSource _remote;

  @override
  Future<ResumeFile> uploadPdf({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    final model = await _remote.uploadPdf(
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
    );
    return model.toEntity();
  }
}
