import '../domain/entities/job.dart';

String interviewModeLabel(InterviewMode mode) {
  return switch (mode) {
    InterviewMode.online => 'สัมภาษณ์ออนไลน์',
    InterviewMode.onSite => 'สัมภาษณ์ออนไซต์',
  };
}

String interviewModeLabelFromApi(String value) {
  return switch (value) {
    'online' => interviewModeLabel(InterviewMode.online),
    'on_site' => interviewModeLabel(InterviewMode.onSite),
    _ => value,
  };
}

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

String deadlineLabel(DateTime deadline) {
  const months = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];
  final local = deadline.toLocal();
  return 'ถึง ${local.day} ${months[local.month - 1]} ${local.year + 543}';
}

String jobStatusLabel(JobStatus status) {
  return switch (status) {
    JobStatus.open => 'เปิดรับ',
    JobStatus.closed => 'ปิดรับ',
  };
}
