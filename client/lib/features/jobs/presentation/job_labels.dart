import '../domain/entities/job.dart';

String workModeLabel(WorkMode mode) {
  return switch (mode) {
    WorkMode.onSite => 'On-site',
    WorkMode.hybrid => 'Hybrid',
    WorkMode.remote => 'Remote',
  };
}

String allowanceLabel(bool hasAllowance, [double? amount]) {
  if (!hasAllowance) return 'ไม่มีเบี้ยเลี้ยง';
  if (amount == null) return 'มีเบี้ยเลี้ยง';
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');
  final cents = parts[1];
  final suffix = cents == '00'
      ? ''
      : '.${cents.endsWith('0') ? cents.substring(0, 1) : cents}';
  return '$whole$suffix บาท';
}

String jobStatusLabel(JobStatus status) {
  return switch (status) {
    JobStatus.open => 'เปิดรับ',
    JobStatus.closed => 'ปิดรับ',
  };
}
