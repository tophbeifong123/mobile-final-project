class ContactLink {
  const ContactLink({
    this.id,
    required this.platform,
    this.label,
    required this.value,
  });

  final String? id;
  final String platform;
  final String? label;
  final String value;
}

class PortfolioLink {
  const PortfolioLink({
    this.id,
    required this.title,
    required this.url,
    this.description,
  });

  final String? id;
  final String title;
  final String url;
  final String? description;
}

class StudentProfile {
  const StudentProfile({
    required this.fullName,
    required this.university,
    required this.major,
    required this.skills,
    this.bio = '',
    this.contactLinks = const [],
    this.portfolioLinks = const [],
    required this.portfolioUrl,
    this.resumeFileName,
    this.resumeObjectKey,
  });

  final String fullName;
  final String university;
  final String major;
  final List<String> skills;
  final String bio;
  final List<ContactLink> contactLinks;
  final List<PortfolioLink> portfolioLinks;
  final String? portfolioUrl;
  final String? resumeFileName;
  final String? resumeObjectKey;

  StudentProfile copyWith({
    String? fullName,
    String? university,
    String? major,
    List<String>? skills,
    String? bio,
    List<ContactLink>? contactLinks,
    List<PortfolioLink>? portfolioLinks,
    String? portfolioUrl,
    String? resumeFileName,
    String? resumeObjectKey,
  }) {
    return StudentProfile(
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      major: major ?? this.major,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      contactLinks: contactLinks ?? this.contactLinks,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      resumeFileName: resumeFileName ?? this.resumeFileName,
      resumeObjectKey: resumeObjectKey ?? this.resumeObjectKey,
    );
  }
}
