import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { CompaniesRepository } from './companies.repository.js';
import { CompanyDashboardSummaryDto } from './dto/company-dashboard-summary.dto.js';

const COMPANY_ONLY = 'เฉพาะบริษัทเท่านั้น';
const COMPANY_NOT_FOUND = 'ไม่พบโปรไฟล์บริษัท';

@Injectable()
export class CompaniesService {
  constructor(private readonly companiesRepository: CompaniesRepository) {}

  async getDashboard(user: AuthUser): Promise<CompanyDashboardSummaryDto> {
    if (user.role !== UserRole.Company) {
      throw new ForbiddenException(COMPANY_ONLY);
    }

    const profile = await this.companiesRepository.findCompanyProfileByUserId(
      user.userId,
    );
    if (!profile) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    const summary = await this.companiesRepository.getDashboardSummary(
      profile.id,
    );

    const dto = new CompanyDashboardSummaryDto();
    dto.totalJobs = summary.totalJobs;
    dto.openJobs = summary.openJobs;
    dto.totalApplicants = summary.totalApplicants;
    return dto;
  }
}
