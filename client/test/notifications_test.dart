import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/notifications/domain/entities/app_notification.dart';
import 'package:client/features/notifications/domain/repositories/notification_repository.dart';
import 'package:client/features/notifications/presentation/providers/notifications_controller.dart';
import 'package:client/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('notifications screen shows empty state when list is empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/student/notifications',
      routes: [
        GoRoute(
          path: '/student/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          notificationRepositoryProvider.overrideWithValue(
            _FakeNotificationRepository(notifications: const []),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('การแจ้งเตือน'), findsOneWidget);
    expect(find.text('ยังไม่มีการแจ้งเตือน'), findsOneWidget);
    expect(
      find.text(
        'จะแสดงเมื่อบริษัทเปลี่ยนสถานะใบสมัคร พร้อมเวลาและสถานะว่าอ่านแล้วหรือยัง กดแล้วเปิดรายละเอียดใบสมัคร',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'notifications screen displays unread/read items with message, timestamp, and status',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final items = [
        AppNotification(
          id: 'n-1',
          applicationId: 'app-1',
          message: 'สถานะใบสมัครงาน Flutter Developer ปรับเป็น In Review',
          isRead: false,
          createdAt: DateTime(2026, 9, 23, 14, 30),
        ),
        AppNotification(
          id: 'n-2',
          applicationId: 'app-2',
          message: 'สถานะใบสมัครงาน Backend Developer ปรับเป็น Accepted',
          isRead: true,
          createdAt: DateTime(2026, 9, 22, 10, 15),
        ),
      ];

      final router = GoRouter(
        initialLocation: '/student/notifications',
        routes: [
          GoRoute(
            path: '/student/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            notificationRepositoryProvider.overrideWithValue(
              _FakeNotificationRepository(notifications: items),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('สถานะใบสมัครงาน Flutter Developer ปรับเป็น In Review'),
        findsOneWidget,
      );
      expect(
        find.text('สถานะใบสมัครงาน Backend Developer ปรับเป็น Accepted'),
        findsOneWidget,
      );
      expect(find.text('ยังไม่ได้อ่าน'), findsOneWidget);
      expect(find.text('อ่านแล้ว'), findsOneWidget);
      expect(find.textContaining('23/09/2026'), findsOneWidget);
      expect(find.textContaining('22/09/2026'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping notification marks as read and navigates to application detail',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeNotificationRepository(
        notifications: [
          AppNotification(
            id: 'n-123',
            applicationId: 'app-456',
            message: 'สถานะใบสมัครปรับเป็น Shortlisted',
            isRead: false,
            createdAt: DateTime(2026, 9, 23, 15, 0),
          ),
        ],
      );

      final router = GoRouter(
        initialLocation: '/student/notifications',
        routes: [
          GoRoute(
            path: '/student/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/student/applications/:applicationId',
            builder: (context, state) {
              return Scaffold(
                body: Text(
                  'Application Detail: ${state.pathParameters['applicationId']}',
                ),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('สถานะใบสมัครปรับเป็น Shortlisted'), findsOneWidget);
      expect(find.text('ยังไม่ได้อ่าน'), findsOneWidget);

      await tester.tap(find.text('สถานะใบสมัครปรับเป็น Shortlisted'));
      await tester.pumpAndSettle();

      // Navigated to detail
      expect(find.text('Application Detail: app-456'), findsOneWidget);
      // markAsRead was invoked on the repository
      expect(fakeRepo.markedReadIds, contains('n-123'));
    },
  );

  testWidgets('shows error state when fetching notifications fails and retry works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepo = _FakeNotificationRepository(
      error: const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'),
    );

    final router = GoRouter(
      initialLocation: '/student/notifications',
      routes: [
        GoRoute(
          path: '/student/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดการแจ้งเตือนไม่ได้'), findsOneWidget);
    expect(find.text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);

    fakeRepo.error = null;
    fakeRepo.notifications = [
      AppNotification(
        id: 'n-recovered',
        applicationId: 'app-rec',
        message: 'การแจ้งเตือนหลัง retry',
        isRead: true,
        createdAt: DateTime(2026, 9, 23, 16, 0),
      ),
    ];

    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('การแจ้งเตือนหลัง retry'), findsOneWidget);
  });
}

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({
    this.notifications = const [],
    this.error,
  });

  List<AppNotification> notifications;
  AppException? error;
  final List<String> markedReadIds = [];

  @override
  Future<List<AppNotification>> fetchAll() async {
    if (error != null) throw error!;
    return notifications;
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    markedReadIds.add(id);
    final index = notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final updated = AppNotification(
        id: notifications[index].id,
        applicationId: notifications[index].applicationId,
        message: notifications[index].message,
        isRead: true,
        createdAt: notifications[index].createdAt,
      );
      notifications[index] = updated;
      return updated;
    }
    return AppNotification(
      id: id,
      applicationId: 'app-default',
      message: '',
      isRead: true,
    );
  }
}
