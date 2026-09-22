import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/applications/presentation/screens/application_detail_screen.dart';
import '../../features/applications/presentation/screens/apply_job_screen.dart';
import '../../features/applications/presentation/screens/my_applications_screen.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/company_dashboard/presentation/screens/company_dashboard_screen.dart';
import '../../features/company_jobs/presentation/screens/applicant_detail_screen.dart';
import '../../features/company_jobs/presentation/screens/applicants_screen.dart';
import '../../features/company_jobs/presentation/screens/job_form_screen.dart';
import '../../features/company_jobs/presentation/screens/manage_jobs_screen.dart';
import '../../features/company_profile/presentation/screens/company_profile_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/jobs/presentation/screens/job_feed_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/resume/presentation/screens/resume_upload_screen.dart';
import '../../features/saved_jobs/presentation/screens/saved_jobs_screen.dart';
import '../../features/student_profile/presentation/screens/student_profile_screen.dart';
import 'company_shell.dart';
import 'student_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (previous, next) {
    refresh.value++;
  });

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      return _redirect(ref.read(authControllerProvider), state.matchedLocation);
    },
    routes: _routes(rootNavigatorKey),
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _redirect(AsyncValue<AuthSession?> auth, String location) {
  final onSplash = location == '/splash';
  final onAuthPage = location == '/login' || location == '/register';

  if (auth.isLoading) {
    return onSplash ? null : '/splash';
  }

  final session = auth.value;
  if (session == null) {
    return onAuthPage ? null : '/login';
  }

  final home = session.role == UserRole.company
      ? '/company/dashboard'
      : '/student/home';
  if (onSplash || onAuthPage) {
    return home;
  }
  if (session.role == UserRole.student && location.startsWith('/company')) {
    return home;
  }
  if (session.role == UserRole.company && location.startsWith('/student')) {
    return home;
  }
  return null;
}

List<RouteBase> _routes(GlobalKey<NavigatorState> rootNavigatorKey) {
  return [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return StudentShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/home',
              builder: (context, state) => const JobFeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/saved',
              builder: (context, state) => const SavedJobsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/applications',
              builder: (context, state) => const MyApplicationsScreen(),
              routes: [
                GoRoute(
                  path: ':applicationId',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    return ApplicationDetailScreen(
                      applicationId: state.pathParameters['applicationId']!,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/profile',
              builder: (context, state) => const StudentProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/student/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/student/resume',
      builder: (context, state) => const ResumeUploadScreen(),
    ),
    GoRoute(
      path: '/student/jobs/:jobId',
      builder: (context, state) {
        return JobDetailScreen(jobId: state.pathParameters['jobId']!);
      },
      routes: [
        GoRoute(
          path: 'apply',
          builder: (context, state) {
            return ApplyJobScreen(jobId: state.pathParameters['jobId']!);
          },
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return CompanyShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/company/dashboard',
              builder: (context, state) => const CompanyDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/company/jobs',
              builder: (context, state) => const ManageJobsScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const JobFormScreen(),
                ),
                GoRoute(
                  path: ':jobId/edit',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    return JobFormScreen(jobId: state.pathParameters['jobId']);
                  },
                ),
                GoRoute(
                  path: ':jobId/applicants',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    return ApplicantsScreen(
                      jobId: state.pathParameters['jobId']!,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: ':applicationId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        return ApplicantDetailScreen(
                          jobId: state.pathParameters['jobId']!,
                          applicationId: state.pathParameters['applicationId']!,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/company/profile',
              builder: (context, state) => const CompanyProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ];
}
