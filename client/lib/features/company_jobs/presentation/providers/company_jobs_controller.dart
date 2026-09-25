import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/company_job_remote_data_source.dart';
import '../../data/repositories/company_job_repository_impl.dart';
import '../../domain/entities/company_job.dart';
import '../../domain/repositories/company_job_repository.dart';

final companyJobRepositoryProvider = Provider<CompanyJobRepository>((ref) {
  return CompanyJobRepositoryImpl(
    CompanyJobRemoteDataSource(ref.watch(dioProvider)),
  );
});

final companyJobListProvider = FutureProvider<List<CompanyJob>>((ref) {
  return ref.watch(companyJobRepositoryProvider).fetchMine();
});

final companyJobDetailProvider = FutureProvider.family<EditableJob, String>((
  ref,
  jobId,
) {
  return ref.watch(companyJobRepositoryProvider).fetchOne(jobId);
});

final companyJobApplicantsProvider =
    FutureProvider.family<List<Applicant>, String>((ref, jobId) {
      return ref.watch(companyJobRepositoryProvider).fetchApplicants(jobId);
    });

final companyApplicantDetailProvider =
    FutureProvider.family<Applicant, ({String jobId, String applicationId})>((
      ref,
      arg,
    ) {
      return ref
          .watch(companyJobRepositoryProvider)
          .fetchApplicant(jobId: arg.jobId, applicationId: arg.applicationId);
    });

final applicantAvatarBytesProvider =
    FutureProvider.family<
      List<int>?,
      ({String jobId, String applicationId, String? avatarKey})
    >((ref, arg) async {
      if (arg.avatarKey == null || arg.avatarKey!.isEmpty) return null;
      final dio = ref.watch(dioProvider);
      try {
        final response = await dio.get<List<int>>(
          ApiConstants.applicantAvatar(arg.jobId, arg.applicationId),
          options: Options(responseType: ResponseType.bytes),
        );
        return response.data;
      } catch (_) {
        return null;
      }
    });

class CompanyJobsController extends Notifier<void> {
  @override
  void build() {
    ref.watch(companyJobRepositoryProvider);
  }

  Future<CreatedJob> create(JobPosting posting) {
    return ref.read(companyJobRepositoryProvider).create(posting);
  }

  Future<EditableJob> update({
    required String jobId,
    required JobPosting posting,
    required int version,
  }) {
    return ref
        .read(companyJobRepositoryProvider)
        .update(jobId: jobId, posting: posting, version: version);
  }

  Future<void> remove(String jobId) {
    return ref.read(companyJobRepositoryProvider).remove(jobId);
  }

  Future<void> updateJobStatus({
    required String jobId,
    required String status,
  }) async {
    await ref
        .read(companyJobRepositoryProvider)
        .setStatus(jobId: jobId, status: status);
    ref.invalidate(companyJobListProvider);
    ref.invalidate(companyJobDetailProvider(jobId));
  }

  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  }) async {
    await ref
        .read(companyJobRepositoryProvider)
        .updateApplicantStatus(
          jobId: jobId,
          applicationId: applicationId,
          status: status,
        );
    ref.invalidate(
      companyApplicantDetailProvider((
        jobId: jobId,
        applicationId: applicationId,
      )),
    );
    ref.invalidate(companyJobApplicantsProvider(jobId));
  }
}

final companyJobsControllerProvider =
    NotifierProvider<CompanyJobsController, void>(CompanyJobsController.new);
