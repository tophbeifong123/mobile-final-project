import '../../domain/entities/job.dart';

class JobModel {
  const JobModel({
    required this.id,
    required this.title,
    required this.companyName,
    required this.province,
    required this.workMode,
    required this.category,
    required this.hasAllowance,
    required this.status,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      province: json['province'] as String,
      workMode: WorkMode.values.byName(json['workMode'] as String),
      category: json['category'] as String,
      hasAllowance: json['hasAllowance'] as bool,
      status: JobStatus.values.byName(json['status'] as String),
    );
  }

  final String id;
  final String title;
  final String companyName;
  final String province;
  final WorkMode workMode;
  final String category;
  final bool hasAllowance;
  final JobStatus status;

  Job toEntity() {
    return Job(
      id: id,
      title: title,
      companyName: companyName,
      province: province,
      workMode: workMode,
      category: category,
      hasAllowance: hasAllowance,
      status: status,
    );
  }
}
