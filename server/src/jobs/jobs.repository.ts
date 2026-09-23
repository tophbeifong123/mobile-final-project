import { Injectable } from '@nestjs/common';
import { DataSource, OptimisticLockVersionMismatchError, QueryFailedError } from 'typeorm';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { Job } from './entities/job.entity.js';
import { SavedJob } from './entities/saved-job.entity.js';
import { JobStatus, type WorkMode } from './job-enums.js';

export interface OpenJobFilter {
  search?: string;
  province?: string;
  workMode?: WorkMode;
  category?: string;
  hasAllowance?: boolean;
  page?: number;
  limit?: number;
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

export interface CompanyJobRecord {
  id: string;
  title: string;
  status: JobStatus;
  applicantCount: number;
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

export interface OwnedJobUpdate {
  id: string;
  companyId: string;
  version: number;
  title: string;
  description: string;
  province: string;
  workMode: WorkMode;
  category: string;
  hasAllowance: boolean;
  requirements: string;
}

export class JobVersionConflictError extends Error {}

@Injectable()
export class JobsRepository {
  constructor(private readonly dataSource: DataSource) {}

  findCompanyId(userId: string): Promise<string | null> {
    return this.dataSource
      .getRepository(CompanyProfile)
      .findOne({ where: { userId }, select: { id: true } })
      .then((profile) => profile?.id ?? null);
  }

  findStudentId(userId: string): Promise<string | null> {
    return this.dataSource
      .getRepository(StudentProfile)
      .findOne({ where: { userId }, select: { id: true } })
      .then((profile) => profile?.id ?? null);
  }

  isSaved(studentId: string, jobId: string): Promise<boolean> {
    return this.dataSource
      .getRepository(SavedJob)
      .existsBy({ studentId, jobId });
  }

  async save(studentId: string, jobId: string): Promise<void> {
    try {
      await this.dataSource.getRepository(SavedJob).insert({ studentId, jobId });
    } catch (error) {
      if (!isUniqueViolation(error)) {
        throw error;
      }
    }
  }

  unsave(studentId: string, jobId: string): Promise<void> {
    return this.dataSource
      .getRepository(SavedJob)
      .delete({ studentId, jobId })
      .then(() => undefined);
  }

  async listSaved(
    studentId: string,
    pagination?: { page?: number; limit?: number },
  ): Promise<{ items: OpenJobRecord[]; total: number }> {
    const qb = this.dataSource
      .getRepository(Job)
      .createQueryBuilder('job')
      .innerJoin(CompanyProfile, 'company', 'company.id = job.companyId')
      .innerJoin(SavedJob, 'saved', 'saved.jobId = job.id')
      .where('saved.studentId = :studentId', { studentId })
      .andWhere('job.status = :status', { status: JobStatus.Open });

    const total = await qb.getCount();
    const page = Math.max(1, pagination?.page ?? 1);
    const limit = Math.min(100, Math.max(1, pagination?.limit ?? 20));
    const skip = (page - 1) * limit;

    const rows = await qb
      .select('job.id', 'id')
      .addSelect('job.title', 'title')
      .addSelect('company.name', 'companyName')
      .addSelect('job.province', 'province')
      .addSelect('job.workMode', 'workMode')
      .addSelect('job.category', 'category')
      .addSelect('job.hasAllowance', 'hasAllowance')
      .addSelect('job.status', 'status')
      .orderBy('saved.createdAt', 'DESC')
      .offset(skip)
      .limit(limit)
      .getRawMany<Record<string, unknown>>();

    return {
      items: rows.map(toOpenJob),
      total,
    };
  }

  async listByCompany(
    companyId: string,
    pagination?: { page?: number; limit?: number },
  ): Promise<{ items: CompanyJobRecord[]; total: number }> {
    const page = Math.max(1, pagination?.page ?? 1);
    const limit = Math.min(100, Math.max(1, pagination?.limit ?? 20));
    const skip = (page - 1) * limit;

    const [jobs, total] = await this.dataSource
      .getRepository(Job)
      .findAndCount({
        where: { companyId },
        select: { id: true, title: true, status: true },
        order: { createdAt: 'DESC' },
        skip,
        take: limit,
      });

    return {
      items: jobs.map((job) => ({
        id: job.id,
        title: job.title,
        status: job.status,
        applicantCount: 0,
      })),
      total,
    };
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

  findById(id: string): Promise<Job | null> {
    return this.dataSource.getRepository(Job).findOne({ where: { id } });
  }

  async updateOwned(input: OwnedJobUpdate): Promise<Job | null> {
    const jobs = this.dataSource.getRepository(Job);
    const job = await jobs.findOne({
      where: { id: input.id, companyId: input.companyId },
    });
    if (!job) {
      return null;
    }
    job.title = input.title;
    job.description = input.description;
    job.province = input.province;
    job.workMode = input.workMode;
    job.category = input.category;
    job.hasAllowance = input.hasAllowance;
    job.requirements = input.requirements;
    job.version = input.version;
    try {
      return await jobs.save(job);
    } catch (error) {
      if (error instanceof OptimisticLockVersionMismatchError) {
        throw new JobVersionConflictError();
      }
      throw error;
    }
  }

  deleteOwned(id: string, companyId: string): Promise<boolean> {
    return this.dataSource
      .getRepository(Job)
      .delete({ id, companyId })
      .then((result) => (result.affected ?? 0) > 0);
  }

  async findOpen(
    filter: OpenJobFilter,
  ): Promise<{ items: OpenJobRecord[]; total: number }> {
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

    const total = await jobs.getCount();
    const page = Math.max(1, filter.page ?? 1);
    const limit = Math.min(100, Math.max(1, filter.limit ?? 20));
    const skip = (page - 1) * limit;

    const rows = await jobs
      .select('job.id', 'id')
      .addSelect('job.title', 'title')
      .addSelect('company.name', 'companyName')
      .addSelect('job.province', 'province')
      .addSelect('job.workMode', 'workMode')
      .addSelect('job.category', 'category')
      .addSelect('job.hasAllowance', 'hasAllowance')
      .addSelect('job.status', 'status')
      .orderBy('job.createdAt', 'DESC')
      .offset(skip)
      .limit(limit)
      .getRawMany<Record<string, unknown>>();

    return {
      items: rows.map(toOpenJob),
      total,
    };
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

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof QueryFailedError &&
    (error.driverError as { code?: string } | undefined)?.code === '23505'
  );
}
