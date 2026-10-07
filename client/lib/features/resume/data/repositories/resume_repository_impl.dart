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

  @override
  Future<List<int>> downloadResumePdf() {
    return _remote.downloadResumePdf();
  }

  @override
  Future<List<int>> downloadDocumentPdf(String id) =>
      _remote.downloadDocumentPdf(id);

  @override
  Future<List<StudentDocument>> listDocuments() => _remote.listDocuments();

  @override
  Future<StudentDocument> uploadDocument({
    required String kind,
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) => _remote.uploadDocument(
    kind: kind,
    filePath: filePath,
    fileName: fileName,
    bytes: bytes,
  );

  @override
  Future<void> deleteDocument(String id) => _remote.deleteDocument(id);
}
