import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Application } from '../applications/entities/application.entity.js';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { Job } from '../jobs/entities/job.entity.js';
import { JobStatus } from '../jobs/job-enums.js';

export interface DashboardSummaryData {
  totalJobs: number;
  openJobs: number;
  totalApplicants: number;
}

@Injectable()
export class CompaniesRepository {
  constructor(private readonly dataSource: DataSource) {}

  findCompanyProfileByUserId(userId: string): Promise<CompanyProfile | null> {
    return this.dataSource
      .getRepository(CompanyProfile)
      .findOne({ where: { userId } });
  }

  async getDashboardSummary(companyId: string): Promise<DashboardSummaryData> {
    const jobRepo = this.dataSource.getRepository(Job);
    const appRepo = this.dataSource.getRepository(Application);

    const [totalJobs, openJobs, totalApplicants] = await Promise.all([
      jobRepo.count({ where: { companyId } }),
      jobRepo.count({ where: { companyId, status: JobStatus.Open } }),
      appRepo
        .createQueryBuilder('app')
        .innerJoin(Job, 'job', 'job.id = app.jobId')
        .where('job.companyId = :companyId', { companyId })
        .getCount(),
    ]);

    return {
      totalJobs,
      openJobs,
      totalApplicants,
    };
  }

  async updateProfile(
    id: string,
    data: { name: string; businessType: string; description: string },
  ): Promise<CompanyProfile | null> {
    const repo = this.dataSource.getRepository(CompanyProfile);
    await repo.update(id, {
      name: data.name,
      businessType: data.businessType,
      description: data.description,
    });
    return repo.findOne({ where: { id } });
  }

  async updateLogoObjectKey(
    id: string,
    logoObjectKey: string,
  ): Promise<CompanyProfile | null> {
    const repo = this.dataSource.getRepository(CompanyProfile);
    await repo.update(id, { logoObjectKey });
    return repo.findOne({ where: { id } });
  }
}
