import '../../../jobs/domain/entities/job.dart';

class SavedJob {
  const SavedJob({
    required this.id,
    required this.title,
    required this.companyName,
    required this.province,
    required this.workMode,
    required this.category,
    required this.hasAllowance,
    this.openings,
    this.allowanceAmount,
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
  final int? openings;
  final double? allowanceAmount;
  final JobStatus status;
  final List<String> skills;
}
