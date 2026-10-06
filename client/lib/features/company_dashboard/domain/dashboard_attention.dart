import '../../company_jobs/domain/entities/company_job.dart';

const dashboardAttentionLimit = 5;
const dashboardDeadlineWindowDays = 7;

enum DashboardJobTask { draft, overdue, dueSoon }

class DashboardManagedJob {
  const DashboardManagedJob({
    required this.job,
    required this.task,
    required this.daysUntilDeadline,
  });

  final CompanyJob job;
  final DashboardJobTask task;
  final int daysUntilDeadline;
}

class DashboardAttention {
  const DashboardAttention({
    required this.pendingReviews,
    required this.jobsToManage,
    required this.hiddenPendingCount,
    required this.hiddenManageCount,
  });

  final List<CompanyJob> pendingReviews;
  final List<DashboardManagedJob> jobsToManage;
  final int hiddenPendingCount;
  final int hiddenManageCount;

  bool get isClear => pendingReviews.isEmpty && jobsToManage.isEmpty;
}

DashboardAttention selectDashboardAttention(
  List<CompanyJob> jobs,
  DateTime now,
) {
  final pending = jobs.where((job) => job.pendingApplicantCount > 0).toList()
    ..sort((a, b) {
      final byCount = b.pendingApplicantCount.compareTo(
        a.pendingApplicantCount,
      );
      if (byCount != 0) return byCount;
      return a.title.compareTo(b.title);
    });

  final today = _dateOnly(now);
  final managed = <DashboardManagedJob>[];
  for (final job in jobs) {
    if (job.status == 'draft') {
      managed.add(
        DashboardManagedJob(
          job: job,
          task: DashboardJobTask.draft,
          daysUntilDeadline: 0,
        ),
      );
      continue;
    }
    if (job.status != 'open' || job.deadline == null) continue;
    final days = _dateOnly(job.deadline!).difference(today).inDays;
    if (days > dashboardDeadlineWindowDays) continue;
    managed.add(
      DashboardManagedJob(
        job: job,
        task: days < 0 ? DashboardJobTask.overdue : DashboardJobTask.dueSoon,
        daysUntilDeadline: days,
      ),
    );
  }
  managed.sort((a, b) {
    final byRank = _taskRank(a.task).compareTo(_taskRank(b.task));
    if (byRank != 0) return byRank;
    if (a.task == DashboardJobTask.draft) {
      return a.job.title.compareTo(b.job.title);
    }
    final byDays = a.daysUntilDeadline.compareTo(b.daysUntilDeadline);
    if (byDays != 0) return byDays;
    return a.job.title.compareTo(b.job.title);
  });

  return DashboardAttention(
    pendingReviews: pending.take(dashboardAttentionLimit).toList(),
    jobsToManage: managed.take(dashboardAttentionLimit).toList(),
    hiddenPendingCount: _hiddenCount(pending.length),
    hiddenManageCount: _hiddenCount(managed.length),
  );
}

String dashboardManagedJobLabel(DashboardManagedJob item) {
  switch (item.task) {
    case DashboardJobTask.draft:
      return 'ฉบับร่าง';
    case DashboardJobTask.overdue:
      return 'เลยกำหนด';
    case DashboardJobTask.dueSoon:
      if (item.daysUntilDeadline == 0) return 'ครบกำหนดวันนี้';
      return 'ครบกำหนดใน ${item.daysUntilDeadline} วัน';
  }
}

int _taskRank(DashboardJobTask task) {
  switch (task) {
    case DashboardJobTask.overdue:
      return 0;
    case DashboardJobTask.dueSoon:
      return 1;
    case DashboardJobTask.draft:
      return 2;
  }
}

int _hiddenCount(int total) {
  final hidden = total - dashboardAttentionLimit;
  return hidden > 0 ? hidden : 0;
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
