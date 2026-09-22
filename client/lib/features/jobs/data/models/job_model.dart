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
      workMode: workModeFromApi(json['workMode'] as String),
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

class JobDetailModel {
  const JobDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.province,
    required this.workMode,
    required this.category,
    required this.hasAllowance,
    required this.requirements,
    required this.status,
    required this.companyName,
    required this.businessType,
    required this.companyDescription,
  });

  factory JobDetailModel.fromJson(Map<String, dynamic> json) {
    return JobDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      province: json['province'] as String,
      workMode: workModeFromApi(json['workMode'] as String),
      category: json['category'] as String,
      hasAllowance: json['hasAllowance'] as bool,
      requirements: json['requirements'] as String,
      status: JobStatus.values.byName(json['status'] as String),
      companyName: json['companyName'] as String,
      businessType: json['businessType'] as String? ?? '',
      companyDescription: json['companyDescription'] as String? ?? '',
    );
  }

  final String id;
  final String title;
  final String description;
  final String province;
  final WorkMode workMode;
  final String category;
  final bool hasAllowance;
  final String requirements;
  final JobStatus status;
  final String companyName;
  final String businessType;
  final String companyDescription;

  JobDetail toEntity() {
    return JobDetail(
      id: id,
      title: title,
      description: description,
      province: province,
      workMode: workMode,
      category: category,
      hasAllowance: hasAllowance,
      requirements: requirements,
      status: status,
      companyName: companyName,
      businessType: businessType,
      companyDescription: companyDescription,
    );
  }
}
