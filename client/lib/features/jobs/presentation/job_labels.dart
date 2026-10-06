import '../domain/entities/job.dart';

String workModeLabel(WorkMode mode) {
  return switch (mode) {
    WorkMode.onSite => 'On-site',
    WorkMode.hybrid => 'Hybrid',
    WorkMode.remote => 'Online',
  };
}

/// Display label for a work-mode value stored by the API.
String workModeLabelFromApi(String value) {
  return switch (value) {
    'on_site' => workModeLabel(WorkMode.onSite),
    'hybrid' => workModeLabel(WorkMode.hybrid),
    'remote' => workModeLabel(WorkMode.remote),
    _ => value,
  };
}

String allowanceLabel(bool hasAllowance, [int? amount]) {
  if (!hasAllowance) {
    return 'ไม่มีเบี้ยเลี้ยง';
  }
  if (amount == null) {
    return 'มีเบี้ยเลี้ยง';
  }
  final digits = amount.toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );
  return 'มีเบี้ยเลี้ยง $grouped บาท';
}

String jobStatusLabel(JobStatus status) {
  return switch (status) {
    JobStatus.open => 'เปิดรับ',
    JobStatus.closed => 'ปิดรับ',
  };
}
