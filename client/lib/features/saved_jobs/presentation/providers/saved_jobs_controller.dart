import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/saved_job_remote_data_source.dart';
import '../../data/repositories/saved_job_repository_impl.dart';
import '../../domain/repositories/saved_job_repository.dart';

final savedJobRepositoryProvider = Provider<SavedJobRepository>((ref) {
  return SavedJobRepositoryImpl(
    SavedJobRemoteDataSource(ref.watch(dioProvider)),
  );
});

class SavedJobsController extends Notifier<void> {
  @override
  void build() {
    ref.watch(savedJobRepositoryProvider);
  }
}

final savedJobsControllerProvider = NotifierProvider<SavedJobsController, void>(
  SavedJobsController.new,
);
