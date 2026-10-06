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
    this.openings,
    this.allowanceAmount,
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
      openings: json['openings'] as int?,
      allowanceAmount: json['allowanceAmount'] as int?,
      status: JobStatus.values.byName(json['status'] as String),
      skills:
          (json['skills'] as List<dynamic>?)
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
  final int? openings;
  final int? allowanceAmount;
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
      openings: openings,
      allowanceAmount: allowanceAmount,
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
    this.openings,
    this.allowanceAmount,
    required this.requirements,
    required this.status,
    required this.companyName,
    required this.businessType,
    required this.companyDescription,
    required this.saved,
    this.companyWebsiteUrl = '',
    this.companySize = '',
    this.companyLocation = '',
    this.companyPerks = const [],
    this.companyLogoAvailable = false,
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
      openings: json['openings'] as int?,
      allowanceAmount: json['allowanceAmount'] as int?,
      requirements: json['requirements'] as String,
      status: JobStatus.values.byName(json['status'] as String),
      companyName: json['companyName'] as String,
      businessType: json['businessType'] as String? ?? '',
      companyDescription: json['companyDescription'] as String? ?? '',
      companyWebsiteUrl: json['companyWebsiteUrl'] as String? ?? '',
      companySize: json['companySize'] as String? ?? '',
      companyLocation: json['companyLocation'] as String? ?? '',
      companyPerks:
          (json['companyPerks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      companyLogoAvailable: json['companyLogoAvailable'] as bool? ?? false,
      saved: json['saved'] as bool? ?? false,
      skills:
          (json['skills'] as List<dynamic>?)
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
  final int? openings;
  final int? allowanceAmount;
  final String requirements;
  final JobStatus status;
  final String companyName;
  final String businessType;
  final String companyDescription;
  final String companyWebsiteUrl;
  final String companySize;
  final String companyLocation;
  final List<String> companyPerks;
  final bool companyLogoAvailable;
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
      openings: openings,
      allowanceAmount: allowanceAmount,
      requirements: requirements,
      status: status,
      companyName: companyName,
      businessType: businessType,
      companyDescription: companyDescription,
      companyWebsiteUrl: companyWebsiteUrl,
      companySize: companySize,
      companyLocation: companyLocation,
      companyPerks: companyPerks,
      companyLogoAvailable: companyLogoAvailable,
      saved: saved,
      skills: skills,
    );
  }
}
