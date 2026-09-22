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
    final model = StudentProfileModel(
      fullName: profile.fullName,
      university: profile.university,
      major: profile.major,
      skills: profile.skills,
      portfolioUrl: profile.portfolioUrl,
    );
    return (await _remote.update(model)).toEntity();
  }
}
