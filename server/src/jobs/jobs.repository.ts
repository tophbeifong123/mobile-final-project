import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { Job } from './entities/job.entity.js';
import { JobStatus, type WorkMode } from './job-enums.js';

export interface OpenJobFilter {
  search?: string;
  province?: string;
  workMode?: WorkMode;
  category?: string;
  hasAllowance?: boolean;
}

export interface OpenJobRecord {
  id: string;
  title: string;
  companyName: string;
  province: string;
  workMode: WorkMode;
  category: string;
  hasAllowance: boolean;
  status: JobStatus;
}

export interface OpenJobDetail extends OpenJobRecord {
  description: string;
  requirements: string;
  businessType: string;
  companyDescription: string;
}

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

  findOpen(filter: OpenJobFilter): Promise<OpenJobRecord[]> {
    const jobs = this.dataSource
      .getRepository(Job)
      .createQueryBuilder('job')
      .innerJoin(CompanyProfile, 'company', 'company.id = job.companyId')
      .where('job.status = :status', { status: JobStatus.Open });

    const search = filter.search?.trim();
    if (search) {
      jobs.andWhere(
        `(job.title ILIKE :search ESCAPE '\\' OR company.name ILIKE :search ESCAPE '\\' OR job.province ILIKE :search ESCAPE '\\')`,
        { search: containsPattern(search) },
      );
    }
    const province = filter.province?.trim();
    if (province) {
      jobs.andWhere(`job.province ILIKE :province ESCAPE '\\'`, {
        province: exactPattern(province),
      });
    }
    if (filter.workMode) {
      jobs.andWhere('job.workMode = :workMode', { workMode: filter.workMode });
    }
    const category = filter.category?.trim();
    if (category) {
      jobs.andWhere(`job.category ILIKE :category ESCAPE '\\'`, {
        category: exactPattern(category),
      });
    }
    if (filter.hasAllowance !== undefined) {
      jobs.andWhere('job.hasAllowance = :hasAllowance', {
        hasAllowance: filter.hasAllowance,
      });
    }

    return jobs
      .select('job.id', 'id')
      .addSelect('job.title', 'title')
      .addSelect('company.name', 'companyName')
      .addSelect('job.province', 'province')
      .addSelect('job.workMode', 'workMode')
      .addSelect('job.category', 'category')
      .addSelect('job.hasAllowance', 'hasAllowance')
      .addSelect('job.status', 'status')
      .orderBy('job.createdAt', 'DESC')
      .getRawMany<Record<string, unknown>>()
      .then((rows) => rows.map(toOpenJob));
  }

  findOpenById(id: string): Promise<OpenJobDetail | null> {
    return this.dataSource
      .getRepository(Job)
      .createQueryBuilder('job')
      .innerJoin(CompanyProfile, 'company', 'company.id = job.companyId')
      .where('job.id = :id', { id })
      .andWhere('job.status = :status', { status: JobStatus.Open })
      .select('job.id', 'id')
      .addSelect('job.title', 'title')
      .addSelect('job.description', 'description')
      .addSelect('job.province', 'province')
      .addSelect('job.workMode', 'workMode')
      .addSelect('job.category', 'category')
      .addSelect('job.hasAllowance', 'hasAllowance')
      .addSelect('job.requirements', 'requirements')
      .addSelect('job.status', 'status')
      .addSelect('company.name', 'companyName')
      .addSelect('company.businessType', 'businessType')
      .addSelect('company.description', 'companyDescription')
      .getRawOne<Record<string, unknown>>()
      .then((row) => (row ? toOpenJobDetail(row) : null));
  }
}

function containsPattern(value: string): string {
  return `%${escapeLike(value)}%`;
}

function exactPattern(value: string): string {
  return escapeLike(value);
}

function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, (char) => `\\${char}`);
}

function readField(row: Record<string, unknown>, key: string): unknown {
  return row[key] ?? row[key.toLowerCase()];
}

function toOpenJob(row: Record<string, unknown>): OpenJobRecord {
  return {
    id: String(readField(row, 'id')),
    title: String(readField(row, 'title') ?? ''),
    companyName: String(readField(row, 'companyName') ?? ''),
    province: String(readField(row, 'province') ?? ''),
    workMode: readField(row, 'workMode') as WorkMode,
    category: String(readField(row, 'category') ?? ''),
    hasAllowance: readBoolean(row, 'hasAllowance'),
    status: readField(row, 'status') as JobStatus,
  };
}

function toOpenJobDetail(row: Record<string, unknown>): OpenJobDetail {
  return {
    ...toOpenJob(row),
    description: String(readField(row, 'description') ?? ''),
    requirements: String(readField(row, 'requirements') ?? ''),
    businessType: String(readField(row, 'businessType') ?? ''),
    companyDescription: String(readField(row, 'companyDescription') ?? ''),
  };
}

function readBoolean(row: Record<string, unknown>, key: string): boolean {
  const value = readField(row, key);
  return value === true || value === 'true';
}
