import '../../domain/entities/company_profile.dart';
import '../../domain/repositories/company_profile_repository.dart';
import '../datasources/company_profile_remote_data_source.dart';
import '../models/company_profile_model.dart';

class CompanyProfileRepositoryImpl implements CompanyProfileRepository {
  CompanyProfileRepositoryImpl(this._remote);

  final CompanyProfileRemoteDataSource _remote;

  @override
  Future<CompanyProfile> fetchMe() async {
    return (await _remote.fetchMe()).toEntity();
  }

  @override
  Future<CompanyProfile> update(CompanyProfile profile) async {
    final model = CompanyProfileModel(
      name: profile.name,
      businessType: profile.businessType,
      description: profile.description,
      logoObjectKey: profile.logoObjectKey,
    );
    return (await _remote.update(model)).toEntity();
  }

  @override
  Future<CompanyProfile> uploadLogo({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    final model = await _remote.uploadLogo(
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
    );
    return model.toEntity();
  }
}
