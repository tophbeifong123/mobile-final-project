import '../../domain/entities/resume_file.dart';

class ResumeFileModel {
  const ResumeFileModel({required this.fileName, required this.objectKey});

  factory ResumeFileModel.fromJson(Map<String, dynamic> json) {
    return ResumeFileModel(
      fileName: json['fileName'] as String? ?? '',
      objectKey: json['objectKey'] as String?,
    );
  }

  final String fileName;
  final String? objectKey;

  ResumeFile toEntity() => ResumeFile(fileName: fileName, objectKey: objectKey);
}
