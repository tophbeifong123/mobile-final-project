import '../../../jobs/domain/entities/job.dart';

class SavedJob extends Job {
  const SavedJob({
    required super.id,
    required super.title,
    required super.companyName,
    required super.province,
    required super.workMode,
    super.interviewMode,
    required super.category,
    required super.hasAllowance,
    required super.status,
    super.openings,
    super.allowanceAmount,
    super.skills,
    super.createdAt,
    super.companyLogoAvailable,
  });
}
