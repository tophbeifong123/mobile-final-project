import 'dart:convert';

import 'package:client/features/jobs/data/models/job_model.dart';
import 'package:client/features/jobs/domain/entities/company_logo.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/error/app_exception.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  for (final fails in [false, true]) {
    testWidgets(
      'company logo raster/failure renders without blocking the job: $fails',
      (tester) async {
        tester.view.physicalSize = const Size(390, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final detail = const JobDetail(
          id: 'job-1',
          title: 'Job',
          description: 'Description',
          province: 'สงขลา',
          workMode: WorkMode.onSite,
          category: 'IT',
          hasAllowance: false,
          requirements: 'Flutter',
          status: JobStatus.open,
          companyName: 'Company',
          businessType: 'IT',
          companyDescription: 'Company description',
          companyLogoAvailable: true,
          saved: false,
        );
        await tester.pumpWidget(
          ProviderScope(
            retry: (retryCount, error) => null,
            overrides: [
              jobDetailProvider('job-1').overrideWith((ref) async => detail),
              jobCompanyLogoProvider('job-1').overrideWith((ref) async {
                if (fails) throw const AppException('Logo unavailable');
                return CompanyLogo(
                  bytes: base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9mQAAAAASUVORK5CYII=',
                  ),
                  mimeType: 'image/png',
                );
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const JobDetailScreen(jobId: 'job-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Company description'), findsOneWidget);
        expect(find.text('สมัครงาน'), findsOneWidget);
        if (fails) {
          expect(find.text('C'), findsOneWidget);
        } else {
          expect(find.byType(Image), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'detail JSON transfers saved company fields and accepts legacy payloads',
    () {
      final json = {
        'id': 'job-1',
        'title': 'Job',
        'description': '',
        'province': 'สงขลา',
        'workMode': 'on_site',
        'category': 'IT',
        'hasAllowance': false,
        'requirements': '',
        'status': 'open',
        'companyName': 'Company',
        'companyWebsiteUrl': 'https://example.com',
        'companyContactLinks': [
          {
            'id': 'c1',
            'platform': 'phone',
            'label': 'ฝ่ายบุคคล',
            'value': '0812345678',
          },
        ],
        'companySize': '51-200',
        'companyLocation': 'อาคาร A',
        'companyPerks': ['MacBook'],
        'companyLogoAvailable': true,
        'companyCoverAvailable': true,
        'createdAt': '2026-10-01T12:00:00.000Z',
        'deadline': '2026-12-31T00:00:00.000Z',
      };
      final detail = JobDetailModel.fromJson(json).toEntity();
      expect(detail.companyWebsiteUrl, 'https://example.com');
      expect(detail.companyContactLinks, hasLength(1));
      expect(detail.companyContactLinks.first.platform, 'phone');
      expect(detail.companyContactLinks.first.value, '0812345678');
      expect(detail.companySize, '51-200');
      expect(detail.companyLocation, 'อาคาร A');
      expect(detail.companyPerks, ['MacBook']);
      expect(detail.companyLogoAvailable, isTrue);
      expect(detail.companyCoverAvailable, isTrue);
      expect(detail.createdAt, DateTime.parse('2026-10-01T12:00:00.000Z'));
      expect(detail.deadline, DateTime.parse('2026-12-31T00:00:00.000Z'));
      for (final key in [
        'companyWebsiteUrl',
        'companyContactLinks',
        'companySize',
        'companyLocation',
        'companyPerks',
        'companyLogoAvailable',
        'companyCoverAvailable',
      ]) {
        json.remove(key);
      }
      final legacy = JobDetailModel.fromJson(json).toEntity();
      expect(legacy.companyPerks, isEmpty);
      expect(legacy.companyContactLinks, isEmpty);
      expect(legacy.companyWebsiteUrl, isEmpty);
      expect(legacy.companyLogoAvailable, isFalse);
      expect(legacy.companyCoverAvailable, isFalse);
      json.remove('createdAt');
      json.remove('deadline');
      final withoutDates = JobDetailModel.fromJson(json).toEntity();
      expect(withoutDates.createdAt, isNull);
      expect(withoutDates.deadline, isNull);
    },
  );

  testWidgets('student sees all saved company metadata and SVG logo in the job', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final detail = const JobDetail(
      id: 'job-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.onSite,
      category: 'IT',
      hasAllowance: true,
      requirements: 'ใช้ Flutter ได้',
      status: JobStatus.open,
      companyName: 'Saved Company',
      businessType: 'Software',
      companyDescription: 'Saved description',
      companyWebsiteUrl: 'https://example.com',
      companyContactLinks: [
        ContactLink(platform: 'phone', label: 'ฝ่ายบุคคล', value: '0812345678'),
        ContactLink(platform: 'email', value: 'hr@example.com'),
      ],
      companySize: '51-200',
      companyLocation: 'อาคาร A ถนนนิพัทธ์อุทิศ',
      companyPerks: ['MacBook', 'Free Lunch'],
      companyLogoAvailable: true,
      saved: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jobDetailProvider('job-1').overrideWith((ref) async => detail),
          jobCompanyLogoProvider('job-1').overrideWith(
            (ref) async => CompanyLogo(
              bytes: utf8.encode(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10" fill="red"/></svg>',
              ),
              mimeType: 'image/svg+xml',
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JobDetailScreen(jobId: 'job-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved Company'), findsOneWidget);
    expect(find.byKey(const Key('company-cover')), findsOneWidget);
    expect(find.text('Software'), findsOneWidget);
    expect(find.text('Saved description'), findsOneWidget);
    expect(find.text('ช่องทางติดต่อ'), findsOneWidget);
    expect(find.text('ฝ่ายบุคคล'), findsOneWidget);
    expect(find.text('0812345678'), findsOneWidget);
    expect(find.text('อีเมล'), findsOneWidget);
    expect(find.text('hr@example.com'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);
    expect(find.text('51-200'), findsOneWidget);
    expect(find.text('อาคาร A ถนนนิพัทธ์อุทิศ'), findsOneWidget);
    expect(find.text('MacBook'), findsOneWidget);
    expect(find.text('Free Lunch'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('ใช้ Flutter ได้'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ใช้ Flutter ได้'), findsOneWidget);
    expect(find.text('สมัครงาน'), findsOneWidget);
  });
  testWidgets('job detail shows the posting and the company', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          jobRepositoryProvider.overrideWithValue(_DetailJobRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JobDetailScreen(jobId: 'job-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('InternFinder'), findsOneWidget);
    expect(find.byKey(const Key('company-cover')), findsOneWidget);
    expect(find.byKey(const Key('company-cover-image')), findsNothing);
    expect(find.text('ซอฟต์แวร์'), findsOneWidget);
    expect(find.text('ช่วยพัฒนาแอป'), findsOneWidget);
    expect(find.text('ใช้ Flutter ได้'), findsOneWidget);
    expect(find.text('สงขลา'), findsOneWidget);
    expect(find.text('On-site'), findsOneWidget);
    expect(find.text('เปิดรับ'), findsOneWidget);
    expect(find.text('IT'), findsOneWidget);
    expect(find.text('รับ 3 คน'), findsOneWidget);
    expect(find.text('มีเบี้ยเลี้ยง 8,000 บาท'), findsOneWidget);
    expect(find.text('ถึง 31 ธ.ค. 2569'), findsOneWidget);
    expect(find.text('วันนี้'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('สมัครงาน'), findsOneWidget);
    expect(find.text('บันทึก'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
    expect(find.text('ยังไม่ได้ระบุ'), findsNothing);
  });

  testWidgets('saved company cover fills the job banner', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const detail = JobDetail(
      id: 'job-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.onSite,
      category: 'IT & Software',
      hasAllowance: false,
      requirements: 'ใช้ Flutter ได้',
      status: JobStatus.open,
      companyName: 'InternFinder',
      businessType: 'ซอฟต์แวร์',
      companyDescription: 'แพลตฟอร์มฝึกงาน',
      companyCoverAvailable: true,
      saved: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jobDetailProvider('job-1').overrideWith((ref) async => detail),
          jobCompanyCoverProvider('job-1').overrideWith(
            (ref) async => CompanyLogo(
              bytes: base64Decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9mQAAAAASUVORK5CYII=',
              ),
              mimeType: 'image/png',
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JobDetailScreen(jobId: 'job-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = find.byKey(const Key('company-cover-image'));
    expect(image, findsOneWidget);
    final size = tester.getSize(image);
    expect(size.width, greaterThan(300));
    expect(size.height, greaterThan(120));
    expect(tester.takeException(), isNull);
  });
}

class _DetailJobRepository implements JobRepository {
  @override
  Future<JobPage> fetchFeed(JobFilter filter) async => const JobPage();

  @override
  Future<JobDetail> fetchDetail(String jobId) async {
    return JobDetail(
      id: 'job-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.onSite,
      category: 'IT',
      hasAllowance: true,
      openings: 3,
      allowanceAmount: 8000,
      requirements: 'ใช้ Flutter ได้',
      skills: const ['Flutter'],
      status: JobStatus.open,
      createdAt: DateTime.now(),
      deadline: DateTime(2026, 12, 31),
      companyName: 'InternFinder',
      businessType: 'ซอฟต์แวร์',
      companyDescription: 'แพลตฟอร์มฝึกงาน',
      saved: false,
    );
  }

  @override
  Future<void> save(String jobId) async {}

  @override
  Future<void> unsave(String jobId) async {}
}
