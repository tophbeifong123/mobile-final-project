class Major {
  const Major({required this.id, required this.nameTh});
  final String id;
  final String nameTh;
}

class MajorChoice {
  const MajorChoice({required this.name, this.id, this.customName});
  factory MajorChoice.master(Major major) =>
      MajorChoice(name: major.nameTh, id: major.id);
  factory MajorChoice.custom(String name) =>
      MajorChoice(name: name, customName: name);
  final String name;
  final String? id;
  final String? customName;
}
