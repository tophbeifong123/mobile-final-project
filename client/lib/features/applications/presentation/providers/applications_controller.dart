import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/datasources/application_remote_data_source.dart';
import '../../data/repositories/application_repository_impl.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/application_repository.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepositoryImpl(
    ApplicationRemoteDataSource(ref.watch(dioProvider)),
  );
});

final applicationDocumentPdfProvider = FutureProvider.autoDispose
    .family<List<int>, ({String applicationId, String documentId})>((ref, key) {
      ref.watch(signedInSessionProvider);
      return ApplicationRemoteDataSource(
        ref.watch(dioProvider),
      ).downloadDocument(key.applicationId, key.documentId);
    });

final myApplicationsProvider = FutureProvider<List<JobApplication>>((ref) {
  ref.watch(signedInSessionProvider);
  return ref.watch(applicationRepositoryProvider).fetchMine();
});

final applicationDetailProvider = FutureProvider.family<JobApplication, String>(
  (ref, applicationId) {
    ref.watch(signedInSessionProvider);
    return ref.watch(applicationRepositoryProvider).fetchDetail(applicationId);
  },
);

class ApplicationsController extends Notifier<void> {
  @override
  void build() {
    ref.watch(applicationRepositoryProvider);
  }
}

final applicationsControllerProvider =
    NotifierProvider<ApplicationsController, void>(ApplicationsController.new);
