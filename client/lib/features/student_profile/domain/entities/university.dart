class University {
  const University({required this.id, required this.nameTh});

  final String id;
  final String nameTh;
}

class UniversityChoice {
  const UniversityChoice.master(this.id, this.name) : customName = null;
  const UniversityChoice.custom(String customName)
    : id = null,
      customName = customName,
      name = customName;

  final String? id;
  final String? customName;
  final String name;
}
