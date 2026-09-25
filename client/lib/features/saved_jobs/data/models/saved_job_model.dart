import '../../../jobs/domain/entities/job.dart';
import '../../domain/entities/saved_job.dart';

class SavedJobModel {
  const SavedJobModel({
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

  factory SavedJobModel.fromJson(Map<String, dynamic> json) {
    return SavedJobModel(
      id: json['id'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      province: json['province'] as String,
      workMode: workModeFromApi(json['workMode'] as String),
      category: json['category'] as String,
      hasAllowance: json['hasAllowance'] as bool,
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
  final JobStatus status;
  final List<String> skills;

  SavedJob toEntity() {
    return SavedJob(
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
