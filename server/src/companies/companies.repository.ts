import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Application } from '../applications/entities/application.entity.js';
import { type ApplicationStatus } from '../applications/application-status.js';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { Job } from '../jobs/entities/job.entity.js';
import { JobStatus } from '../jobs/job-enums.js';

export interface DashboardSummaryData {
  totalJobs: number;
  openJobs: number;
  totalApplicants: number;
  pendingApplicants: number;
}

@Injectable()
export class CompaniesRepository {
  constructor(private readonly dataSource: DataSource) {}

  findCompanyProfileByUserId(userId: string): Promise<CompanyProfile | null> {
    return this.dataSource
      .getRepository(CompanyProfile)
      .findOne({ where: { userId }, relations: { province: true } });
  }

  async getDashboardSummary(
    companyId: string,
    pendingStatuses: readonly ApplicationStatus[],
  ): Promise<DashboardSummaryData> {
    const jobRepo = this.dataSource.getRepository(Job);
    const appRepo = this.dataSource.getRepository(Application);

    const [totalJobs, openJobs, totalApplicants, pendingApplicants] = await Promise.all([
      jobRepo.count({ where: { companyId } }),
      jobRepo.count({ where: { companyId, status: JobStatus.Open } }),
      appRepo
        .createQueryBuilder('app')
        .innerJoin(Job, 'job', 'job.id = app.jobId')
        .where('job.companyId = :companyId', { companyId })
        .getCount(),
      appRepo
        .createQueryBuilder('app')
        .innerJoin(Job, 'job', 'job.id = app.jobId')
        .where('job.companyId = :companyId', { companyId })
        .andWhere('app.status IN (:...pendingStatuses)', { pendingStatuses })
        .getCount(),
    ]);

    return {
      totalJobs,
      openJobs,
      totalApplicants,
      pendingApplicants,
    };
  }

  async updateProfile(
    id: string,
    data: Partial<
      Pick<
        CompanyProfile,
        | 'name'
        | 'businessType'
        | 'description'
        | 'websiteUrl'
        | 'contactLinks'
        | 'companySize'
        | 'perks'
        | 'provinceId'
        | 'location'
      >
    >,
  ): Promise<CompanyProfile | null> {
    const repo = this.dataSource.getRepository(CompanyProfile);
    await repo.update(id, data);
    return repo.findOne({ where: { id }, relations: { province: true } });
  }

  async updateLogoObjectKey(
    id: string,
    logoObjectKey: string | null,
  ): Promise<CompanyProfile | null> {
    const repo = this.dataSource.getRepository(CompanyProfile);
    await repo.update(id, { logoObjectKey });
    return repo.findOne({ where: { id }, relations: { province: true } });
  }

  async updateCoverObjectKey(
    id: string,
    coverObjectKey: string | null,
  ): Promise<CompanyProfile | null> {
    const repo = this.dataSource.getRepository(CompanyProfile);
    await repo.update(id, { coverObjectKey });
    return repo.findOne({ where: { id }, relations: { province: true } });
  }
}
