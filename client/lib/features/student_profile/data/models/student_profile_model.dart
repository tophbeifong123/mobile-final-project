import '../../domain/entities/student_profile.dart';

class StudentProfileModel {
  const StudentProfileModel({
    required this.fullName,
    required this.university,
    required this.major,
    required this.skills,
    required this.portfolioUrl,
    this.resumeFileName,
    this.resumeObjectKey,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      fullName: json['fullName'] as String? ?? '',
      university: json['university'] as String? ?? '',
      major: json['major'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>? ?? const [])
          .map((skill) => skill as String)
          .toList(),
      portfolioUrl: json['portfolioUrl'] as String?,
      resumeFileName: json['resumeFileName'] as String?,
      resumeObjectKey: json['resumeObjectKey'] as String?,
    );
  }

  final String fullName;
  final String university;
  final String major;
  final List<String> skills;
  final String? portfolioUrl;
  final String? resumeFileName;
  final String? resumeObjectKey;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'university': university,
      'major': major,
      'skills': skills,
      'portfolioUrl': portfolioUrl,
    };
  }

  StudentProfile toEntity() {
    return StudentProfile(
      fullName: fullName,
      university: university,
      major: major,
      skills: skills,
      portfolioUrl: portfolioUrl,
      resumeFileName: resumeFileName,
      resumeObjectKey: resumeObjectKey,
    );
  }
}
