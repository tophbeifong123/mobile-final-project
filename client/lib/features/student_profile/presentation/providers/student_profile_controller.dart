import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/student_profile_remote_data_source.dart';
import '../../data/repositories/student_profile_repository_impl.dart';
import '../../domain/repositories/student_profile_repository.dart';

final studentProfileRepositoryProvider = Provider<StudentProfileRepository>((
  ref,
) {
  return StudentProfileRepositoryImpl(
    StudentProfileRemoteDataSource(ref.watch(dioProvider)),
  );
});

class StudentProfileController extends Notifier<void> {
  @override
  void build() {
    ref.watch(studentProfileRepositoryProvider);
  }
}

final studentProfileControllerProvider =
    NotifierProvider<StudentProfileController, void>(
      StudentProfileController.new,
    );
