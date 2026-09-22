import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { Job } from './entities/job.entity.js';
import { JobStatus, type WorkMode } from './job-enums.js';

export interface NewJob {
  companyId: string;
  title: string;
  description: string;
  province: string;
  workMode: WorkMode;
  category: string;
  hasAllowance: boolean;
  requirements: string;
}

@Injectable()
export class JobsRepository {
  constructor(private readonly dataSource: DataSource) {}

  findCompanyId(userId: string): Promise<string | null> {
    return this.dataSource
      .getRepository(CompanyProfile)
      .findOne({ where: { userId }, select: { id: true } })
      .then((profile) => profile?.id ?? null);
  }

  create(input: NewJob): Promise<Job> {
    const jobs = this.dataSource.getRepository(Job);
    return jobs.save(
      jobs.create({
        companyId: input.companyId,
        title: input.title,
        description: input.description,
        province: input.province,
        workMode: input.workMode,
        category: input.category,
        hasAllowance: input.hasAllowance,
        requirements: input.requirements,
        status: JobStatus.Open,
      }),
    );
  }
}
