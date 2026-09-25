import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { CompanyJobItemDto } from './dto/company-job-item.dto.js';
import { CreateJobDto } from './dto/create-job.dto.js';
import { JobDetailDto } from './dto/job-detail.dto.js';
import { JobDto } from './dto/job.dto.js';
import { JobFeedItemDto } from './dto/job-feed-item.dto.js';
import { JobFeedQueryDto } from './dto/job-feed-query.dto.js';
import { PaginatedCompanyJobsDto } from './dto/paginated-company-jobs.dto.js';
import { PaginatedJobsDto } from './dto/paginated-jobs.dto.js';
import { PaginationQueryDto } from '../common/dto/pagination-query.dto.js';
import { toPaginatedResult } from '../common/dto/paginated-result.js';
import { UpdateJobDto } from './dto/update-job.dto.js';
import { UpdateJobStatusDto } from './dto/update-job-status.dto.js';
import { JobStatus } from './job-enums.js';
import { JobsRepository, JobVersionConflictError } from './jobs.repository.js';

const COMPANY_ONLY = 'เฉพาะบริษัทเท่านั้น';
const COMPANY_NOT_FOUND = 'ไม่พบโปรไฟล์บริษัท';
const STUDENT_ONLY = 'เฉพาะนักศึกษาเท่านั้น';
const JOB_NOT_FOUND = 'ไม่พบประกาศ';
const STUDENT_NOT_FOUND = 'ไม่พบโปรไฟล์';
const NOT_OWNED = 'เฉพาะประกาศของบริษัทนี้';
const STALE_JOB = 'ประกาศถูกแก้ไปแล้ว โหลดข้อมูลใหม่';

@Injectable()
export class JobsService {
  constructor(private readonly jobsRepository: JobsRepository) {}

  async create(user: AuthUser, dto: CreateJobDto): Promise<JobDto> {
    if (user.role !== UserRole.Company) {
      throw new ForbiddenException(COMPANY_ONLY);
    }

    const companyId = await this.jobsRepository.findCompanyId(user.userId);
    if (!companyId) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    const job = await this.jobsRepository.create({
      companyId,
      title: dto.title.trim(),
      description: dto.description.trim(),
      province: dto.province.trim(),
      workMode: dto.workMode,
      category: dto.category.trim(),
      hasAllowance: dto.hasAllowance,
      requirements: dto.requirements.trim(),
      skills: dto.skills ?? [],
    });
    return toDto(job);
  }

  async listOpen(
    user: AuthUser,
    query: JobFeedQueryDto,
  ): Promise<PaginatedJobsDto> {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
    const page = Math.max(1, query.page ?? 1);
    const limit = Math.min(100, Math.max(1, query.limit ?? 20));
    const result = await this.jobsRepository.findOpen({
      search: query.search,
      province: query.province,
      workMode: query.workMode,
      category: query.category,
      hasAllowance: query.hasAllowance,
      skills: query.skills,
      page,
      limit,
    });
    return toPaginatedResult(
      result.items.map(toFeedItem),
      result.total,
      page,
      limit,
    );
  }

  async getOpen(user: AuthUser, jobId: string): Promise<JobDetailDto> {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
    const job = await this.jobsRepository.findOpenById(jobId);
    if (!job) {
      throw new NotFoundException(JOB_NOT_FOUND);
    }
    const studentId = await this.jobsRepository.findStudentId(user.userId);
    const saved = studentId
      ? await this.jobsRepository.isSaved(studentId, jobId)
      : false;
    return toDetail(job, saved);
  }

  async save(user: AuthUser, jobId: string): Promise<void> {
    const studentId = await this.requireStudentId(user);
    const job = await this.jobsRepository.findOpenById(jobId);
    if (!job) {
      throw new NotFoundException(JOB_NOT_FOUND);
    }
    await this.jobsRepository.save(studentId, jobId);
  }

  async unsave(user: AuthUser, jobId: string): Promise<void> {
    const studentId = await this.requireStudentId(user);
    await this.jobsRepository.unsave(studentId, jobId);
  }

  async listSaved(
    user: AuthUser,
    pagination?: PaginationQueryDto,
  ): Promise<PaginatedJobsDto> {
    const studentId = await this.requireStudentId(user);
    const page = Math.max(1, pagination?.page ?? 1);
    const limit = Math.min(100, Math.max(1, pagination?.limit ?? 20));
    const result = await this.jobsRepository.listSaved(studentId, {
      page,
      limit,
    });
    return toPaginatedResult(
      result.items.map(toFeedItem),
      result.total,
      page,
      limit,
    );
  }

  async listMine(
    user: AuthUser,
    pagination?: PaginationQueryDto,
  ): Promise<PaginatedCompanyJobsDto> {
    if (user.role !== UserRole.Company) {
      throw new ForbiddenException(COMPANY_ONLY);
    }
    const companyId = await this.jobsRepository.findCompanyId(user.userId);
    if (!companyId) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }
    const page = Math.max(1, pagination?.page ?? 1);
    const limit = Math.min(100, Math.max(1, pagination?.limit ?? 20));
    const result = await this.jobsRepository.listByCompany(companyId, {
      page,
      limit,
    });
    return toPaginatedResult(
      result.items.map(toCompanyItem),
      result.total,
      page,
      limit,
    );
  }

  async getMine(user: AuthUser, jobId: string): Promise<JobDto> {
    const companyId = await this.requireCompanyId(user);
    const job = await this.requireOwnedJob(companyId, jobId);
    return toDto(job);
  }

  async update(user: AuthUser, jobId: string, dto: UpdateJobDto): Promise<JobDto> {
    const companyId = await this.requireCompanyId(user);
    await this.requireOwnedJob(companyId, jobId);
    try {
      const updated = await this.jobsRepository.updateOwned({
        id: jobId,
        companyId,
        version: dto.version,
        title: dto.title.trim(),
        description: dto.description.trim(),
        province: dto.province.trim(),
        workMode: dto.workMode,
        category: dto.category.trim(),
        hasAllowance: dto.hasAllowance,
        requirements: dto.requirements.trim(),
        skills: dto.skills ?? [],
      });
      if (!updated) {
        throw new NotFoundException(JOB_NOT_FOUND);
      }
      return toDto(updated);
    } catch (error) {
      if (error instanceof JobVersionConflictError) {
        throw new ConflictException(STALE_JOB);
      }
      throw error;
    }
  }

  async updateStatus(
    user: AuthUser,
    jobId: string,
    dto: UpdateJobStatusDto,
  ): Promise<JobDto> {
    const companyId = await this.requireCompanyId(user);
    await this.requireOwnedJob(companyId, jobId);
    const updated = await this.jobsRepository.updateOwnedStatus(
      jobId,
      companyId,
      dto.status,
    );
    if (!updated) {
      throw new NotFoundException(JOB_NOT_FOUND);
    }
    return toDto(updated);
  }

  async remove(user: AuthUser, jobId: string): Promise<void> {
    const companyId = await this.requireCompanyId(user);
    await this.requireOwnedJob(companyId, jobId);
    const deleted = await this.jobsRepository.deleteOwned(jobId, companyId);
    if (!deleted) {
      throw new NotFoundException(JOB_NOT_FOUND);
    }
  }

  private async requireCompanyId(user: AuthUser): Promise<string> {
    if (user.role !== UserRole.Company) {
      throw new ForbiddenException(COMPANY_ONLY);
    }
    const companyId = await this.jobsRepository.findCompanyId(user.userId);
    if (!companyId) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }
    return companyId;
  }

  private async requireOwnedJob(companyId: string, jobId: string) {
    const job = await this.jobsRepository.findById(jobId);
    if (!job) {
      throw new NotFoundException(JOB_NOT_FOUND);
    }
    if (job.companyId !== companyId) {
      throw new ForbiddenException(NOT_OWNED);
    }
    return job;
  }

  private async requireStudentId(user: AuthUser): Promise<string> {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
    const studentId = await this.jobsRepository.findStudentId(user.userId);
    if (!studentId) {
      throw new NotFoundException(STUDENT_NOT_FOUND);
    }
    return studentId;
  }
}

function toDto(job: {
  id: string;
  title: string;
  description: string;
  province: string;
  workMode: JobDto['workMode'];
  category: string;
  hasAllowance: boolean;
  requirements: string;
  skills?: string[];
  status: JobStatus;
  version: number;
}): JobDto {
  const dto = new JobDto();
  dto.id = job.id;
  dto.title = job.title;
  dto.description = job.description;
  dto.province = job.province;
  dto.workMode = job.workMode;
  dto.category = job.category;
  dto.hasAllowance = job.hasAllowance;
  dto.requirements = job.requirements;
  dto.skills = job.skills ?? [];
  dto.status = job.status;
  dto.version = job.version;
  return dto;
}

function toDetail(
  job: {
    id: string;
    title: string;
    description: string;
    province: string;
    workMode: JobDetailDto['workMode'];
    category: string;
    hasAllowance: boolean;
    requirements: string;
    skills?: string[];
    status: JobStatus;
    companyName: string;
    businessType: string;
    companyDescription: string;
  },
  saved: boolean,
): JobDetailDto {
  const dto = new JobDetailDto();
  dto.id = job.id;
  dto.title = job.title;
  dto.description = job.description;
  dto.province = job.province;
  dto.workMode = job.workMode;
  dto.category = job.category;
  dto.hasAllowance = job.hasAllowance;
  dto.requirements = job.requirements;
  dto.skills = job.skills ?? [];
  dto.status = job.status;
  dto.companyName = job.companyName;
  dto.businessType = job.businessType;
  dto.companyDescription = job.companyDescription;
  dto.saved = saved;
  return dto;
}

function toCompanyItem(job: {
  id: string;
  title: string;
  status: JobStatus;
  applicantCount: number;
}): CompanyJobItemDto {
  const dto = new CompanyJobItemDto();
  dto.id = job.id;
  dto.title = job.title;
  dto.status = job.status;
  dto.applicantCount = job.applicantCount;
  return dto;
}

function toFeedItem(job: {
  id: string;
  title: string;
  companyName: string;
  province: string;
  workMode: JobFeedItemDto['workMode'];
  category: string;
  hasAllowance: boolean;
  skills?: string[];
  status: JobStatus;
}): JobFeedItemDto {
  const dto = new JobFeedItemDto();
  dto.id = job.id;
  dto.title = job.title;
  dto.companyName = job.companyName;
  dto.province = job.province;
  dto.workMode = job.workMode;
  dto.category = job.category;
  dto.hasAllowance = job.hasAllowance;
  dto.skills = job.skills ?? [];
  dto.status = job.status;
  return dto;
}
