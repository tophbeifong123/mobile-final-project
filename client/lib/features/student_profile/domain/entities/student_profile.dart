class StudentProfile {
  const StudentProfile({
    required this.fullName,
    required this.university,
    required this.major,
    required this.skills,
    required this.portfolioUrl,
  });

  final String fullName;
  final String university;
  final String major;
  final List<String> skills;
  final String? portfolioUrl;
}
