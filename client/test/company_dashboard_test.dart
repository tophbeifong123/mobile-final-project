import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_dashboard/domain/entities/company_dashboard_summary.dart';
import 'package:client/features/company_dashboard/domain/repositories/company_dashboard_repository.dart';
import 'package:client/features/company_dashboard/presentation/providers/company_dashboard_controller.dart';
import 'package:client/features/company_dashboard/presentation/screens/company_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('company dashboard displays summary statistics correctly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = _MockDashboardRepository(
      summary: const CompanyDashboardSummary(
        totalJobs: 5,
        openJobs: 3,
        totalApplicants: 12,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyDashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('แดชบอร์ดบริษัท'), findsOneWidget);
    expect(find.text('ประกาศทั้งหมด'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('ประกาศที่เปิดรับ'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('ผู้สมัครทั้งหมด'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    expect(find.text('สร้างประกาศ'), findsOneWidget);
    expect(find.text('จัดการประกาศ'), findsOneWidget);
  });

  testWidgets('company dashboard displays 0 applicants when empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = _MockDashboardRepository(
      summary: const CompanyDashboardSummary(
        totalJobs: 0,
        openJobs: 0,
        totalApplicants: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyDashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ประกาศทั้งหมด'), findsOneWidget);
    expect(find.text('ผู้สมัครทั้งหมด'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
  });

  testWidgets('company dashboard shows error view and retries', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = _FailingDashboardRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyDashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลแดชบอร์ดไม่สำเร็จ'), findsOneWidget);
    expect(find.text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
    expect(find.text('ลองใหม่อีกครั้ง'), findsOneWidget);

    // Now make it succeed on retry
    mockRepo.shouldFail = false;
    await tester.tap(find.text('ลองใหม่อีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('แดชบอร์ดบริษัท'), findsOneWidget);
    expect(find.text('ประกาศทั้งหมด'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}

class _MockDashboardRepository implements CompanyDashboardRepository {
  _MockDashboardRepository({required this.summary});

  final CompanyDashboardSummary summary;

  @override
  Future<CompanyDashboardSummary> fetchSummary() async {
    return summary;
  }
}

class _FailingDashboardRepository implements CompanyDashboardRepository {
  bool shouldFail = true;

  @override
  Future<CompanyDashboardSummary> fetchSummary() async {
    if (shouldFail) {
      throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }
    return const CompanyDashboardSummary(
      totalJobs: 4,
      openJobs: 2,
      totalApplicants: 8,
    );
  }
}
