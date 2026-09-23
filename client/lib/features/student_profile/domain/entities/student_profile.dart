class StudentProfile {
  const StudentProfile({
    required this.fullName,
    required this.university,
    required this.major,
    required this.skills,
    required this.portfolioUrl,
    this.resumeFileName,
    this.resumeObjectKey,
  });

  final String fullName;
  final String university;
  final String major;
  final List<String> skills;
  final String? portfolioUrl;
  final String? resumeFileName;
  final String? resumeObjectKey;
}
