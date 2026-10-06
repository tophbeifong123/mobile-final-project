import '../entities/student_profile.dart';
import '../entities/university.dart';
import '../entities/major.dart';

abstract class StudentProfileRepository {
  Future<StudentProfile> fetchMe();
  Future<List<University>> searchUniversities(String query) async => const [];
  Future<List<Major>> searchMajors(String query) async => const [];

  Future<StudentProfile> update(StudentProfile profile);

  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  });

  Future<StudentProfile> deleteAvatar();
}
