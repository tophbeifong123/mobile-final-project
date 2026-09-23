import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/application_remote_data_source.dart';
import '../../data/repositories/application_repository_impl.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/application_repository.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepositoryImpl(
    ApplicationRemoteDataSource(ref.watch(dioProvider)),
  );
});

final myApplicationsProvider = FutureProvider<List<JobApplication>>((ref) {
  return ref.watch(applicationRepositoryProvider).fetchMine();
});

final applicationDetailProvider =
    FutureProvider.family<JobApplication, String>((ref, applicationId) {
  return ref.watch(applicationRepositoryProvider).fetchDetail(applicationId);
});

class ApplicationsController extends Notifier<void> {
  @override
  void build() {
    ref.watch(applicationRepositoryProvider);
  }
}

final applicationsControllerProvider =
    NotifierProvider<ApplicationsController, void>(ApplicationsController.new);
