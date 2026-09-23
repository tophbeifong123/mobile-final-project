import '../entities/resume_file.dart';

abstract class ResumeRepository {
  Future<ResumeFile> uploadPdf({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  });
}
