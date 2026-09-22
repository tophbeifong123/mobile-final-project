import '../domain/entities/job.dart';

String workModeLabel(WorkMode mode) {
  return switch (mode) {
    WorkMode.onSite => 'On-site',
    WorkMode.hybrid => 'Hybrid',
    WorkMode.remote => 'Remote',
  };
}

String allowanceLabel(bool hasAllowance) {
  return hasAllowance ? 'มีเบี้ยเลี้ยง' : 'ไม่มีเบี้ยเลี้ยง';
}
