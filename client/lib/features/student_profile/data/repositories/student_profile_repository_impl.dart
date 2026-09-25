import '../../domain/entities/student_profile.dart';
import '../../domain/repositories/student_profile_repository.dart';
import '../datasources/student_profile_remote_data_source.dart';
import '../models/student_profile_model.dart';

class StudentProfileRepositoryImpl implements StudentProfileRepository {
  StudentProfileRepositoryImpl(this._remote);

  final StudentProfileRemoteDataSource _remote;

  @override
  Future<StudentProfile> fetchMe() async {
    return (await _remote.fetchMe()).toEntity();
  }

  @override
  Future<StudentProfile> update(StudentProfile profile) async {
    final model = StudentProfileModel.fromEntity(profile);
    return (await _remote.update(model)).toEntity();
  }

  @override
  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    final model = await _remote.uploadAvatar(
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
    );
    return model.toEntity();
  }

  @override
  Future<StudentProfile> deleteAvatar() async {
    final model = await _remote.deleteAvatar();
    return model.toEntity();
  }
}
