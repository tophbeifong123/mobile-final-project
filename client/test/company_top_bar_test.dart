import 'dart:async';

import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/router/app_router.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/company_top_bar.dart';
import 'package:client/features/auth/domain/entities/auth_session.dart';
import 'package:client/features/auth/presentation/providers/auth_controller.dart';
import 'package:client/features/company_dashboard/domain/entities/company_dashboard_summary.dart';
import 'package:client/features/company_dashboard/presentation/providers/company_dashboard_controller.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/presentation/providers/company_jobs_controller.dart';
import 'package:client/features/company_profile/domain/entities/company_profile.dart';
import 'package:client/features/company_profile/presentation/providers/company_profile_controller.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/presentation/widgets/feed_top_bar.dart';
import 'package:client/features/notifications/domain/entities/app_notification.dart';
import 'package:client/features/notifications/presentation/providers/notifications_controller.dart';
import 'package:client/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:client/features/saved_jobs/presentation/providers/saved_jobs_controller.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _backKey = Key('company-top-bar-back');
const _companyPages = [
  (path: '/company/dashboard', title: 'แดชบอร์ดบริษัท', secondary: false),
  (path: '/company/jobs', title: 'ประกาศของบริษัท', secondary: false),
  (path: '/company/profile', title: 'โปรไฟล์บริษัท', secondary: false),
  (path: '/company/jobs/new', title: 'สร้างประกาศ', secondary: true),
  (path: '/company/jobs/job-1/edit', title: 'แก้ประกาศ', secondary: true),
  (
    path: '/company/jobs/job-1/applicants',
    title: 'รายชื่อผู้สมัคร',
    secondary: true,
  ),
  (
    path: '/company/jobs/job-1/applicants/app-1',
    title: 'รายละเอียดผู้สมัคร',
    secondary: true,
  ),
];

void main() {
  for (final page in _companyPages) {
    for (final state in _LoadState.values) {
      if (page.path.endsWith('/new') && state != _LoadState.ready) continue;

      testWidgets('${page.path} uses the company header in ${state.name}', (
        tester,
      ) async {
        final router = await _mountApp(tester, loadState: state);
        router.go(page.path);
        await _pumpState(tester, state);

        final header = find.byType(CompanyTopBar);
        expect(header, findsOneWidget);
        expect(tester.widget<CompanyTopBar>(header).title, page.title);
        expect(
          find.descendant(of: header, matching: find.text('InternMatch')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: header, matching: find.text('บริษัท')),
          findsOneWidget,
        );
        expect(
          find.byKey(_backKey),
          page.secondary ? findsOneWidget : findsNothing,
        );
        if (!page.secondary) {
          expect(find.text('Dashboard'), findsOneWidget);
          expect(find.text('Jobs'), findsOneWidget);
          expect(find.text('Profile'), findsOneWidget);
        }
        _expectNoBell();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('back on a pushed page returns to its actual previous page', (
    tester,
  ) async {
    final router = await _mountApp(tester);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/company/dashboard',
    );
    unawaited(router.push('/company/jobs/new'));
    await tester.pumpAndSettle();
    expect(find.byKey(_backKey), findsOneWidget);

    await tester.tap(find.byKey(_backKey));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/company/dashboard',
    );
    expect(find.byKey(_backKey), findsNothing);
  });

  for (final page in _companyPages.where((page) => page.secondary)) {
    testWidgets('${page.path} back works when opened directly', (tester) async {
      final router = await _mountApp(tester);
      router.go(page.path);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_backKey));
      await tester.pumpAndSettle();

      final expectedParent = page.path.endsWith('/app-1')
          ? '/company/jobs/job-1/applicants'
          : '/company/jobs';
      expect(router.routeInformationProvider.value.uri.path, expectedParent);
      expect(tester.takeException(), isNull);
    });
  }

  for (final parent in ['/company/jobs', '/company/jobs/job-1/applicants']) {
    testWidgets('header falls back to $parent without navigation history', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/standalone-detail',
        routes: [
          GoRoute(
            path: '/standalone-detail',
            builder: (context, state) => Scaffold(
              appBar: CompanyTopBar(
                title: 'รายละเอียด',
                showBack: true,
                backLocation: parent,
              ),
            ),
          ),
          GoRoute(path: parent, builder: (context, state) => const Scaffold()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();
      expect(router.canPop(), isFalse);

      await tester.tap(find.byKey(_backKey));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, parent);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the registered app routes have student-only notifications', (
    tester,
  ) async {
    final router = await _mountApp(tester);
    final notificationPaths = _registeredPaths(
      router.configuration.routes,
    ).where((path) => path.contains('notification')).toList();

    expect(notificationPaths, ['/student/notifications']);
  });

  testWidgets('company cannot open the student notifications route', (
    tester,
  ) async {
    final router = await _mountApp(tester);
    router.go('/student/notifications');
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/company/dashboard',
    );
    expect(find.byType(NotificationsScreen), findsNothing);
    expect(find.byType(CompanyTopBar), findsOneWidget);
    _expectNoBell();
  });

  testWidgets('student bell still opens the real notifications screen', (
    tester,
  ) async {
    final router = await _mountApp(tester, role: UserRole.student);
    final bell = find.descendant(
      of: find.byType(FeedTopBar),
      matching: find.byIcon(Icons.notifications_none_rounded),
    );
    expect(bell, findsOneWidget);
    await tester.tap(bell);
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(
      GoRouterState.of(
        tester.element(find.byType(NotificationsScreen)),
      ).uri.path,
      '/student/notifications',
    );
    expect(router.canPop(), isTrue);
    expect(find.byType(CompanyTopBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('company header fits a narrow screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const Scaffold(
          appBar: CompanyTopBar(
            title: 'รายละเอียดผู้สมัครตำแหน่งวิศวกรซอฟต์แวร์',
            showBack: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('บริษัท'), findsOneWidget);
    expect(find.byKey(_backKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

enum _LoadState { ready, loading, error }

Future<T> _result<T>(_LoadState state, T value) {
  return switch (state) {
    _LoadState.ready => Future.value(value),
    _LoadState.loading => Completer<T>().future,
    _LoadState.error => Future.error(const AppException('โหลดข้อมูลไม่สำเร็จ')),
  };
}

Future<void> _pumpState(WidgetTester tester, _LoadState state) async {
  if (state == _LoadState.loading) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    await tester.pumpAndSettle();
  }
}

Future<GoRouter> _mountApp(
  WidgetTester tester, {
  UserRole role = UserRole.company,
  _LoadState loadState = _LoadState.ready,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
      authControllerProvider.overrideWith(() => _SignedInController(role)),
      companyDashboardSummaryProvider.overrideWith(
        (ref) => _result(
          loadState,
          const CompanyDashboardSummary(
            totalJobs: 1,
            openJobs: 1,
            totalApplicants: 1,
          ),
        ),
      ),
      companyJobListProvider.overrideWith(
        (ref) => _result(loadState, const []),
      ),
      companyJobDetailProvider.overrideWith(
        (ref, jobId) => _result(loadState, _editableJob),
      ),
      companyJobApplicantsProvider.overrideWith(
        (ref, jobId) => _result(loadState, const []),
      ),
      companyApplicantDetailProvider.overrideWith(
        (ref, arg) => _result(loadState, _applicant),
      ),
      companyProfileControllerProvider.overrideWith(
        () => _ProfileController(loadState),
      ),
      jobFeedProvider.overrideWith((ref) async => const JobPage()),
      savedJobsProvider.overrideWith((ref) async => const []),
      studentProfileControllerProvider.overrideWith(_StudentController.new),
      notificationsProvider.overrideWith(_EmptyNotifications.new),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.future);
  final router = container.read(goRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await _pumpState(tester, loadState);
  return router;
}

void _expectNoBell() {
  for (final icon in [
    Icons.notifications,
    Icons.notifications_none,
    Icons.notifications_outlined,
    Icons.notifications_rounded,
    Icons.notifications_none_rounded,
    Icons.notifications_active,
    LucideIcons.bell,
    LucideIcons.bellDot,
    LucideIcons.bellRing,
  ]) {
    expect(find.byIcon(icon), findsNothing);
  }
}

Iterable<String> _registeredPaths(
  List<RouteBase> routes, [
  String parent = '',
]) sync* {
  for (final route in routes) {
    final path = route is GoRoute
        ? route.path.startsWith('/')
              ? route.path
              : '$parent/${route.path}'
        : parent;
    if (route is GoRoute) yield path;
    yield* _registeredPaths(route.routes, path);
  }
}

const _editableJob = EditableJob(
  id: 'job-1',
  title: 'Flutter Intern',
  description: 'Build mobile apps',
  province: 'สงขลา',
  workMode: 'hybrid',
  category: 'Software',
  hasAllowance: false,
  requirements: 'Flutter',
  status: 'open',
  version: 1,
);
const _applicant = Applicant(
  applicationId: 'app-1',
  fullName: 'มีนา',
  university: 'PSU',
  major: 'IT',
  status: 'submitted',
  coverLetter: 'อยากฝึกงาน',
);

class _SignedInController extends AuthController {
  _SignedInController(this.role);
  final UserRole role;

  @override
  Future<AuthSession?> build() async => AuthSession(
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
    role: role,
  );
}

class _ProfileController extends CompanyProfileController {
  _ProfileController(this.loadState);
  final _LoadState loadState;

  @override
  Future<CompanyProfile> build() => _result(
    loadState,
    const CompanyProfile(
      name: 'Test Company',
      businessType: 'Software',
      description: '',
      logoObjectKey: null,
    ),
  );
}

class _StudentController extends StudentProfileController {
  @override
  Future<StudentProfile> build() async => const StudentProfile(
    fullName: 'มีนา',
    university: 'PSU',
    major: 'IT',
    skills: [],
    portfolioUrl: null,
  );
}

class _EmptyNotifications extends NotificationsNotifier {
  @override
  Future<List<AppNotification>> build() async => const [];
}
