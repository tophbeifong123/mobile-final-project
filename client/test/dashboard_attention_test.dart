import 'package:client/features/company_dashboard/domain/dashboard_attention.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 6);

  CompanyJob job({
    required String id,
    required String title,
    String status = 'open',
    int pending = 0,
    DateTime? deadline,
  }) {
    return CompanyJob(
      id: id,
      title: title,
      status: status,
      workMode: 'hybrid',
      applicantCount: pending,
      pendingApplicantCount: pending,
      deadline: deadline,
    );
  }

  test('pending reviews are the jobs with the most waiting applications', () {
    final attention = selectDashboardAttention([
      job(id: 'low', title: 'น้อย', pending: 1),
      job(id: 'high', title: 'มาก', pending: 4),
      job(id: 'none', title: 'ไม่มี', pending: 0),
      job(id: 'mid', title: 'กลาง', pending: 2),
    ], now);

    expect(attention.pendingReviews.map((item) => item.id), [
      'high',
      'mid',
      'low',
    ]);
    expect(attention.hiddenPendingCount, 0);
  });

  test('only five pending jobs stay on the dashboard', () {
    final attention = selectDashboardAttention([
      for (var index = 0; index < 6; index++)
        job(id: 'job-$index', title: 'งาน $index', pending: index + 1),
    ], now);

    expect(attention.pendingReviews, hasLength(5));
    expect(attention.pendingReviews.first.id, 'job-5');
    expect(attention.hiddenPendingCount, 1);
  });

  test('drafts and open jobs due within a week need managing', () {
    final attention = selectDashboardAttention([
      job(id: 'later', title: 'อีกเดือน', deadline: DateTime(2026, 11, 6)),
      job(id: 'today', title: 'วันนี้', deadline: DateTime(2026, 10, 6, 18)),
      job(id: 'draft', title: 'ฉบับร่าง', status: 'draft'),
      job(id: 'late', title: 'เลยแล้ว', deadline: DateTime(2026, 10, 1)),
      job(
        id: 'closed',
        title: 'ปิดแล้ว',
        status: 'closed',
        deadline: DateTime(2026, 9, 1),
      ),
      job(id: 'soon', title: 'อีกเจ็ดวัน', deadline: DateTime(2026, 10, 13)),
    ], now);

    expect(attention.jobsToManage.map((item) => item.job.id), [
      'late',
      'today',
      'soon',
      'draft',
    ]);
    expect(dashboardManagedJobLabel(attention.jobsToManage[0]), 'เลยกำหนด');
    expect(
      dashboardManagedJobLabel(attention.jobsToManage[1]),
      'ครบกำหนดวันนี้',
    );
    expect(
      dashboardManagedJobLabel(attention.jobsToManage[2]),
      'ครบกำหนดใน 7 วัน',
    );
    expect(dashboardManagedJobLabel(attention.jobsToManage[3]), 'ฉบับร่าง');
  });
}
