enum WorkMode { onSite, hybrid, remote }

enum JobStatus { open, closed }

class JobFilter {
  const JobFilter({
    this.search = '',
    this.province,
    this.workMode,
    this.category,
    this.hasAllowance,
    this.skills = const [],
    this.page = 1,
    this.limit = 20,
  });

  final String search;
  final String? province;
  final WorkMode? workMode;
  final String? category;
  final bool? hasAllowance;
  final List<String> skills;
  final int page;
  final int limit;

  bool get hasCriteria =>
      search.trim().isNotEmpty ||
      province != null ||
      workMode != null ||
      (category != null && category!.trim().isNotEmpty) ||
      hasAllowance != null ||
      skills.isNotEmpty;

  bool get hasFilters =>
      (province != null && province!.trim().isNotEmpty) ||
      workMode != null ||
      (category != null && category!.trim().isNotEmpty) ||
      hasAllowance != null ||
      skills.isNotEmpty;

  int get filterCount {
    var count = 0;
    if (province != null && province!.trim().isNotEmpty) count++;
    if (workMode != null) count++;
    if (category != null && category!.trim().isNotEmpty) count++;
    if (hasAllowance != null) count++;
    if (skills.isNotEmpty) count += skills.length;
    return count;
  }

  JobFilter copyWith({
    String? search,
    String? province,
    bool clearProvince = false,
    WorkMode? workMode,
    bool clearWorkMode = false,
    String? category,
    bool clearCategory = false,
    bool? hasAllowance,
    bool clearAllowance = false,
    List<String>? skills,
    bool clearSkills = false,
    int? page,
    int? limit,
  }) {
    return JobFilter(
      search: search ?? this.search,
      province: clearProvince ? null : province ?? this.province,
      workMode: clearWorkMode ? null : workMode ?? this.workMode,
      category: clearCategory ? null : category ?? this.category,
      hasAllowance: clearAllowance ? null : hasAllowance ?? this.hasAllowance,
      skills: clearSkills ? const [] : skills ?? this.skills,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobFilter &&
        other.search == search &&
        other.province == province &&
        other.workMode == workMode &&
        other.category == category &&
        other.hasAllowance == hasAllowance &&
        _listEquals(other.skills, skills) &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(
    search,
    province,
    workMode,
    category,
    hasAllowance,
    Object.hashAll(skills),
    page,
    limit,
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class Job {
  const Job({
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

  final String id;
  final String title;
  final String companyName;
  final String province;
  final WorkMode workMode;
  final String category;
  final bool hasAllowance;
  final JobStatus status;
  final List<String> skills;
}

class JobDetail {
  const JobDetail({
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
}

String workModeToApi(WorkMode mode) {
  return switch (mode) {
    WorkMode.onSite => 'on_site',
    WorkMode.hybrid => 'hybrid',
    WorkMode.remote => 'remote',
  };
}

WorkMode workModeFromApi(String value) {
  return switch (value) {
    'on_site' => WorkMode.onSite,
    'hybrid' => WorkMode.hybrid,
    'remote' => WorkMode.remote,
    _ => throw FormatException('รูปแบบงานไม่รู้จัก'),
  };
}
