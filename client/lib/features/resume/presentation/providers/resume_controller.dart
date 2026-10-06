import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/resume_remote_data_source.dart';
import '../../data/repositories/resume_repository_impl.dart';
import '../../domain/repositories/resume_repository.dart';
import '../../domain/entities/resume_file.dart';

final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return ResumeRepositoryImpl(ResumeRemoteDataSource(ref.watch(dioProvider)));
});

class ResumeController extends Notifier<void> {
  @override
  void build() {
    ref.watch(resumeRepositoryProvider);
  }
}

final resumeControllerProvider = NotifierProvider<ResumeController, void>(
  ResumeController.new,
);

final studentDocumentsProvider =
    FutureProvider.autoDispose<List<StudentDocument>>((ref) {
      return ref.watch(resumeRepositoryProvider).listDocuments();
    });

final resumePdfBytesProvider = FutureProvider.autoDispose<List<int>>((
  ref,
) async {
  final repo = ref.watch(resumeRepositoryProvider);
  return repo.downloadResumePdf();
});

final studentDocumentPdfBytesProvider = FutureProvider.autoDispose
    .family<List<int>, String>((ref, documentId) {
      return ref
          .watch(resumeRepositoryProvider)
          .downloadDocumentPdf(documentId);
    });
