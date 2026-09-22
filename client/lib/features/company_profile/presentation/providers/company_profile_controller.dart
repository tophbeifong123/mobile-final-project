import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/company_profile_remote_data_source.dart';
import '../../data/repositories/company_profile_repository_impl.dart';
import '../../domain/repositories/company_profile_repository.dart';

final companyProfileRepositoryProvider = Provider<CompanyProfileRepository>((
  ref,
) {
  return CompanyProfileRepositoryImpl(
    CompanyProfileRemoteDataSource(ref.watch(dioProvider)),
  );
});

class CompanyProfileController extends Notifier<void> {
  @override
  void build() {
    ref.watch(companyProfileRepositoryProvider);
  }
}

final companyProfileControllerProvider =
    NotifierProvider<CompanyProfileController, void>(
      CompanyProfileController.new,
    );
