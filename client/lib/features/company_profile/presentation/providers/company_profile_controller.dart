import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/company_profile_remote_data_source.dart';
import '../../data/repositories/company_profile_repository_impl.dart';
import '../../domain/entities/company_profile.dart';
import '../../domain/repositories/company_profile_repository.dart';

final companyProfileRepositoryProvider = Provider<CompanyProfileRepository>((
  ref,
) {
  return CompanyProfileRepositoryImpl(
    CompanyProfileRemoteDataSource(ref.watch(dioProvider)),
  );
});

class CompanyProfileController extends AsyncNotifier<CompanyProfile> {
  @override
  Future<CompanyProfile> build() {
    return ref.watch(companyProfileRepositoryProvider).fetchMe();
  }

  Future<CompanyProfile> save(CompanyProfile profile) async {
    final saved = await ref
        .read(companyProfileRepositoryProvider)
        .update(profile);
    state = AsyncData(saved);
    return saved;
  }

  Future<CompanyProfile> uploadLogo({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    final updated = await ref
        .read(companyProfileRepositoryProvider)
        .uploadLogo(filePath: filePath, fileName: fileName, bytes: bytes);
    state = AsyncData(updated);
    return updated;
  }

  Future<CompanyProfile> deleteLogo() async {
    final updated = await ref
        .read(companyProfileRepositoryProvider)
        .deleteLogo();
    state = AsyncData(updated);
    return updated;
  }

  Future<CompanyProfile> uploadCover({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    final updated = await ref
        .read(companyProfileRepositoryProvider)
        .uploadCover(filePath: filePath, fileName: fileName, bytes: bytes);
    state = AsyncData(updated);
    return updated;
  }

  Future<CompanyProfile> deleteCover() async {
    final updated = await ref
        .read(companyProfileRepositoryProvider)
        .deleteCover();
    state = AsyncData(updated);
    return updated;
  }
}

final companyProfileControllerProvider =
    AsyncNotifierProvider<CompanyProfileController, CompanyProfile>(
      CompanyProfileController.new,
    );

final companyLogoBytesProvider = FutureProvider.family<List<int>?, String?>((
  ref,
  logoKey,
) async {
  if (logoKey == null || logoKey.isEmpty) return null;
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<List<int>>(
      ApiConstants.companyLogo,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  } catch (_) {
    return null;
  }
});

final companyCoverBytesProvider = FutureProvider.family<List<int>?, String?>((
  ref,
  coverKey,
) async {
  if (coverKey == null || coverKey.isEmpty) return null;
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<List<int>>(
      ApiConstants.companyCover,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  } catch (_) {
    return null;
  }
});
