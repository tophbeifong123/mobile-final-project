import '../../domain/entities/saved_job.dart';

class SavedJobModel {
  const SavedJobModel({required this.jobId, required this.title});

  factory SavedJobModel.fromJson(Map<String, dynamic> json) {
    return SavedJobModel(
      jobId: json['jobId'] as String,
      title: json['title'] as String,
    );
  }

  final String jobId;
  final String title;

  SavedJob toEntity() => SavedJob(jobId: jobId, title: title);
}
