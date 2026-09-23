enum ApplicationStatus { submitted, reviewing, accepted, rejected }

extension ApplicationStatusX on ApplicationStatus {
  String get labelTh {
    switch (this) {
      case ApplicationStatus.submitted:
        return 'ยื่นใบสมัครแล้ว';
      case ApplicationStatus.reviewing:
        return 'กำลังพิจารณา';
      case ApplicationStatus.accepted:
        return 'ผ่านการคัดเลือก';
      case ApplicationStatus.rejected:
        return 'ไม่ผ่านการคัดเลือก';
    }
  }

  String get labelEn {
    switch (this) {
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.reviewing:
        return 'Reviewing';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    required this.createdAt,
  });

  final String id;
  final ApplicationStatus? fromStatus;
  final ApplicationStatus toStatus;
  final DateTime createdAt;
}

class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.coverLetter,
    this.jobId,
    this.province,
    this.workMode,
    this.category,
    this.hasAllowance,
    this.resumeObjectKey,
    this.createdAt,
    this.timeline = const [],
  });

  final String id;
  final String? jobId;
  final String jobTitle;
  final String companyName;
  final String? province;
  final String? workMode;
  final String? category;
  final bool? hasAllowance;
  final ApplicationStatus status;
  final String coverLetter;
  final String? resumeObjectKey;
  final DateTime? createdAt;
  final List<TimelineEvent> timeline;
}
