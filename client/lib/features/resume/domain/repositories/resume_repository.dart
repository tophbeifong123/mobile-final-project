import '../entities/resume_file.dart';

abstract class ResumeRepository {
  Future<ResumeFile> uploadPdf({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  });

  Future<List<int>> downloadResumePdf();
  Future<List<int>> downloadDocumentPdf(String id);
  Future<List<StudentDocument>> listDocuments();
  Future<StudentDocument> uploadDocument({
    required String kind,
    required String filePath,
    required String fileName,
    List<int>? bytes,
  });
  Future<void> deleteDocument(String id);
}
