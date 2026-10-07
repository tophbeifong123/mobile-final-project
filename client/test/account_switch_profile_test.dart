import 'package:client/features/auth/domain/entities/auth_session.dart';
import 'package:client/features/auth/presentation/providers/auth_controller.dart';
import 'package:client/features/student_profile/domain/entities/major.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/entities/university.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new login replaces the previous account profile', () async {
    final repository = _SwitchableProfileRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SwitchableAuth.new),
        studentProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final first = await container.read(studentProfileControllerProvider.future);
    expect(first.fullName, 'อลิซ');

    repository.name = 'บ็อบ';
    (container.read(authControllerProvider.notifier) as _SwitchableAuth).use(
      const AuthSession(
        accessToken: 'bob-token',
        refreshToken: 'bob-refresh',
        role: UserRole.student,
      ),
    );

    final second = await container.read(
      studentProfileControllerProvider.future,
    );
    expect(second.fullName, 'บ็อบ');
    expect(repository.fetches, greaterThan(1));
  });
}

class _SwitchableAuth extends AuthController {
  @override
  Future<AuthSession?> build() async {
    return const AuthSession(
      accessToken: 'alice-token',
      refreshToken: 'alice-refresh',
      role: UserRole.student,
    );
  }

  void use(AuthSession? session) {
    state = AsyncData(session);
  }
}

class _SwitchableProfileRepository implements StudentProfileRepository {
  String name = 'อลิซ';
  var fetches = 0;

  StudentProfile get _profile => StudentProfile(
    fullName: name,
    university: 'มหาวิทยาลัยทดสอบ',
    major: 'คอมพิวเตอร์',
    skills: const [],
    portfolioUrl: null,
  );

  @override
  Future<StudentProfile> fetchMe() async {
    fetches++;
    return _profile;
  }

  @override
  Future<List<University>> searchUniversities(String query) async => const [];

  @override
  Future<List<Major>> searchMajors(String query) async => const [];

  @override
  Future<StudentProfile> update(StudentProfile profile) async => profile;

  @override
  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async => _profile;

  @override
  Future<StudentProfile> deleteAvatar() async => _profile;
}
