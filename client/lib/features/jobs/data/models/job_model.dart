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
    this.skills = const [],
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
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
  final List<String> skills;

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
      skills: skills,
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
    required this.saved,
    this.skills = const [],
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
      saved: json['saved'] as bool? ?? false,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
  final bool saved;
  final List<String> skills;

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
      saved: saved,
      skills: skills,
    );
  }
}
