import '../entities/student_profile.dart';

abstract class StudentProfileRepository {
  Future<StudentProfile> fetchMe();

  Future<StudentProfile> update(StudentProfile profile);

  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  });

  Future<StudentProfile> deleteAvatar();
}
