/// Preset Skills Master Data categorized for student and job posting selection
class PresetSkills {
  PresetSkills._();

  static const Map<String, List<String>> categories = {
    'IT & Software': [
      'Flutter',
      'Dart',
      'React',
      'Next.js',
      'Node.js',
      'TypeScript',
      'JavaScript',
      'Python',
      'Java',
      'Kotlin',
      'Swift',
      'Go',
      'C#',
      'SQL',
      'PostgreSQL',
      'MongoDB',
      'Git',
      'Docker',
      'REST API',
      'HTML/CSS',
    ],
    'Design & UX/UI': [
      'Figma',
      'UI Design',
      'UX Research',
      'Design System',
      'Wireframing',
      'Prototyping',
      'Adobe XD',
      'Illustrator',
      'Photoshop',
      'Graphic Design',
      'User Testing',
    ],
    'Marketing': [
      'Digital Marketing',
      'Content Creator',
      'SEO',
      'SEM',
      'Social Media',
      'Copywriting',
      'Google Analytics',
      'Facebook Ads',
      'TikTok Ads',
      'Email Marketing',
      'Brand Strategy',
    ],
    'Data': [
      'Python',
      'SQL',
      'Power BI',
      'Tableau',
      'Data Analysis',
      'Pandas',
      'NumPy',
      'Machine Learning',
      'Data Visualization',
      'Excel',
      'Statistics',
    ],
  };

  /// Returns a deduplicated flat list of all preset skills
  static List<String> get all {
    final seen = <String>{};
    final result = <String>[];
    for (final list in categories.values) {
      for (final skill in list) {
        if (seen.add(skill.toLowerCase())) {
          result.add(skill);
        }
      }
    }
    return result;
  }

  /// Get preset skills belonging to a specific category
  static List<String> getByCategory(String category) {
    return categories[category] ?? [];
  }

  /// Search preset skills by query string (case-insensitive substring match)
  static List<String> search(String query, {String? category}) {
    final trimmed = query.trim().toLowerCase();
    final source = category != null && categories.containsKey(category)
        ? categories[category]!
        : all;

    if (trimmed.isEmpty) return source;

    return source
        .where((skill) => skill.toLowerCase().contains(trimmed))
        .toList();
  }
}
