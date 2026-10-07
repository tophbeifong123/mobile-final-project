class ResumeFile {
  const ResumeFile({required this.fileName, required this.objectKey});

  final String fileName;
  final String? objectKey;
}

class StudentDocument {
  const StudentDocument({
    required this.id,
    required this.type,
    required this.fileName,
  });
  final String id;
  final String type;
  final String fileName;
}
