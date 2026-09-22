import '../entities/student_profile.dart';

abstract class StudentProfileRepository {
  Future<StudentProfile> fetchMe();

  Future<StudentProfile> update(StudentProfile profile);
}
