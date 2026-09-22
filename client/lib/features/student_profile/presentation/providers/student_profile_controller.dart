import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/student_profile_remote_data_source.dart';
import '../../data/repositories/student_profile_repository_impl.dart';
import '../../domain/entities/student_profile.dart';
import '../../domain/repositories/student_profile_repository.dart';

final studentProfileRepositoryProvider = Provider<StudentProfileRepository>((
  ref,
) {
  return StudentProfileRepositoryImpl(
    StudentProfileRemoteDataSource(ref.watch(dioProvider)),
  );
});

class StudentProfileController extends AsyncNotifier<StudentProfile> {
  @override
  Future<StudentProfile> build() {
    return ref.watch(studentProfileRepositoryProvider).fetchMe();
  }

  Future<StudentProfile> save(StudentProfile profile) async {
    final saved = await ref
        .read(studentProfileRepositoryProvider)
        .update(profile);
    state = AsyncData(saved);
    return saved;
  }
}

final studentProfileControllerProvider =
    AsyncNotifierProvider<StudentProfileController, StudentProfile>(
      StudentProfileController.new,
    );
