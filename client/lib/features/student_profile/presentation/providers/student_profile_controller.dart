import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
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

  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    final updated = await ref
        .read(studentProfileRepositoryProvider)
        .uploadAvatar(filePath: filePath, fileName: fileName, bytes: bytes);
    state = AsyncData(updated);
    return updated;
  }

  Future<StudentProfile> deleteAvatar() async {
    final updated = await ref
        .read(studentProfileRepositoryProvider)
        .deleteAvatar();
    state = AsyncData(updated);
    return updated;
  }
}

final studentProfileControllerProvider =
    AsyncNotifierProvider<StudentProfileController, StudentProfile>(
      StudentProfileController.new,
    );

final studentAvatarBytesProvider = FutureProvider.family<List<int>?, String?>((
  ref,
  avatarKey,
) async {
  if (avatarKey == null || avatarKey.isEmpty) return null;
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<List<int>>(
      ApiConstants.studentAvatar,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  } catch (_) {
    return null;
  }
});
