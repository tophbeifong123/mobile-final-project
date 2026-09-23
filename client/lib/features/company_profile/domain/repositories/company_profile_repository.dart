import '../entities/company_profile.dart';

abstract class CompanyProfileRepository {
  Future<CompanyProfile> fetchMe();

  Future<CompanyProfile> update(CompanyProfile profile);

  Future<CompanyProfile> uploadLogo({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  });
}
