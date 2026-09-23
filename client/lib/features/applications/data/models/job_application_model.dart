import '../../domain/entities/job_application.dart';

class TimelineEventModel {
  const TimelineEventModel({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    required this.createdAt,
  });

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    return TimelineEventModel(
      id: json['id'] as String,
      fromStatus: json['fromStatus'] != null
          ? ApplicationStatus.values.byName(json['fromStatus'] as String)
          : null,
      toStatus: ApplicationStatus.values.byName(json['toStatus'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final ApplicationStatus? fromStatus;
  final ApplicationStatus toStatus;
  final DateTime createdAt;

  TimelineEvent toEntity() {
    return TimelineEvent(
      id: id,
      fromStatus: fromStatus,
      toStatus: toStatus,
      createdAt: createdAt,
    );
  }
}

class JobApplicationModel {
  const JobApplicationModel({
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

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    final jobObj = json['job'] as Map<String, dynamic>?;
    final jobTitle = jobObj != null
        ? (jobObj['title'] as String? ?? '')
        : (json['jobTitle'] as String? ?? '');
    final companyName = jobObj != null
        ? (jobObj['companyName'] as String? ?? '')
        : (json['companyName'] as String? ?? '');

    final rawTimeline = json['timeline'] as List<dynamic>?;
    final timeline = rawTimeline != null
        ? rawTimeline
            .map((item) => TimelineEventModel.fromJson(item as Map<String, dynamic>).toEntity())
            .toList()
        : <TimelineEvent>[];

    return JobApplicationModel(
      id: json['id'] as String,
      jobId: json['jobId'] as String? ?? jobObj?['id'] as String?,
      jobTitle: jobTitle,
      companyName: companyName,
      province: jobObj?['province'] as String?,
      workMode: jobObj?['workMode'] as String?,
      category: jobObj?['category'] as String?,
      hasAllowance: jobObj?['hasAllowance'] as bool?,
      status: ApplicationStatus.values.byName(json['status'] as String),
      coverLetter: json['coverLetter'] as String? ?? '',
      resumeObjectKey: json['resumeObjectKey'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      timeline: timeline,
    );
  }

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

  JobApplication toEntity() {
    return JobApplication(
      id: id,
      jobId: jobId,
      jobTitle: jobTitle,
      companyName: companyName,
      province: province,
      workMode: workMode,
      category: category,
      hasAllowance: hasAllowance,
      status: status,
      coverLetter: coverLetter,
      resumeObjectKey: resumeObjectKey,
      createdAt: createdAt,
      timeline: timeline,
    );
  }
}
