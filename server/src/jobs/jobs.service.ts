import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { ProvincesService } from '../provinces/provinces.service.js';
import { StorageService } from '../storage/storage.service.js';
import { CompanyJobItemDto } from './dto/company-job-item.dto.js';
import { CreateJobDto } from './dto/create-job.dto.js';
import { JobDetailDto } from './dto/job-detail.dto.js';
import { CompanyOwnedJobDto } from './dto/company-owned-job.dto.js';
import { JobDto } from './dto/job.dto.js';
import { JobFeedItemDto } from './dto/job-feed-item.dto.js';
import { JobFeedQueryDto } from './dto/job-feed-query.dto.js';
import { PaginatedCompanyJobsDto } from './dto/paginated-company-jobs.dto.js';
import { PaginatedJobsDto } from './dto/paginated-jobs.dto.js';
import { PaginationQueryDto } from '../common/dto/pagination-query.dto.js';
import { toPaginatedResult } from '../common/dto/paginated-result.js';
import { UpdateJobDto } from './dto/update-job.dto.js';
import { UpdateJobStatusDto } from './dto/update-job-status.dto.js';
import { isJobCategory } from './job-categories.js';
import { JobStatus, WorkMode } from './job-enums.js';
import { JobsRepository, JobVersionConflictError } from './jobs.repository.js';

function categoryOf(value: string): string {
  const category = value.trim();
  if (!isJobCategory(category)) {
    throw new BadRequestException('เลือกหมวดงานจากรายการ');
  }
  return category;
}

function allowanceAmountOf(dto: {
  hasAllowance: boolean;
  allowanceAmount?: number | null;
}): number | null {
  if (!dto.hasAllowance) {
    if (dto.allowanceAmount != null) {
      throw new BadRequestException('ไม่มีเบี้ยเลี้ยงจึงไม่ต้องใส่จำนวนเงิน');
    }
    return null;
  }
  const amount = dto.allowanceAmount;
  if (
    amount == null ||
    !Number.isInteger(amount) ||
    amount < 1 ||
    amount > 1_000_000
  ) {
    throw new BadRequestException('ระบุจำนวนเบี้ยเลี้ยงเป็นบาท');
  }
  return amount;
}

const COMPANY_ONLY = 'เฉพาะบริษัทเท่านั้น';
const COMPANY_NOT_FOUND = 'ไม่พบโปรไฟล์บริษัท';
const STUDENT_ONLY = 'เฉพาะนักศึกษาเท่านั้น';
const JOB_NOT_FOUND = 'ไม่พบประกาศ';
const STUDENT_NOT_FOUND = 'ไม่พบโปรไฟล์';
const NOT_OWNED = 'เฉพาะประกาศของบริษัทนี้';
const STALE_JOB = 'ประกาศถูกแก้ไปแล้ว โหลดข้อมูลใหม่';

@Injectable()
export class JobsService {
  constructor(
    private readonly jobsRepository: JobsRepository,
    private readonly provincesService: ProvincesService,
    private readonly storageService: StorageService,
  ) {}

  async create(user: AuthUser, dto: CreateJobDto): Promise<JobDto> {
    if (user.role !== UserRole.Company) {
      throw new ForbiddenException(COMPANY_ONLY);
    }

    const companyId = await this.jobsRepository.findCompanyId(user.userId);
    if (!companyId) {
      throw new NotFoundException(COMPANY_NOT_FOUND);
    }

    const province = await this.provincesService.resolveName(dto.province);
    const job = await this.jobsRepository.create({
      openings: openingsOf(dto.openings),
      companyId,
      title: dto.title.trim(),
      description: dto.description.trim(),
      province,
      workMode: dto.workMode,
      category: categoryOf(dto.category),
      hasAllowance: dto.hasAllowance,
      allowanceAmount: allowanceAmountOf(dto),
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
    const province = query.province
      ? await this.provincesService.resolveName(query.province)
      : undefined;
    const result = await this.jobsRepository.findOpen({
      search: query.search,
      province,
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

  async getCompanyLogo(
    user: AuthUser,
    jobId: string,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
    const job = await this.jobsRepository.findOpenById(jobId);
    if (!job) throw new NotFoundException(JOB_NOT_FOUND);
    const key = job.companyLogoObjectKey;
    if (!key) throw new NotFoundException('ไม่พบโลโก้บริษัท');
    const buffer = await this.storageService.get(key);
    if (!buffer) throw new NotFoundException('ไม่พบโลโก้บริษัท');
    return { buffer, mimeType: imageMimeType(key) };
  }

  async getCompanyCover(
    user: AuthUser,
    jobId: string,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
    const job = await this.jobsRepository.findOpenById(jobId);
    if (!job) throw new NotFoundException(JOB_NOT_FOUND);
    const key = job.companyCoverObjectKey;
    if (!key) throw new NotFoundException('ไม่พบรูปหน้าปกบริษัท');
    const buffer = await this.storageService.get(key);
    if (!buffer) throw new NotFoundException('ไม่พบรูปหน้าปกบริษัท');
    return { buffer, mimeType: imageMimeType(key) };
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

  async getMine(user: AuthUser, jobId: string): Promise<CompanyOwnedJobDto> {
    const companyId = await this.requireCompanyId(user);
    const job = await this.requireOwnedJob(companyId, jobId);
    const counts = await this.jobsRepository.countApplicants(jobId);
    return toOwnedDto(job, counts);
  }

  async update(
    user: AuthUser,
    jobId: string,
    dto: UpdateJobDto,
  ): Promise<JobDto> {
    const companyId = await this.requireCompanyId(user);
    await this.requireOwnedJob(companyId, jobId);
    const province = await this.provincesService.resolveName(dto.province);
    try {
      const updated = await this.jobsRepository.updateOwned({
        openings: openingsOf(dto.openings),
        id: jobId,
        companyId,
        version: dto.version,
        title: dto.title.trim(),
        description: dto.description.trim(),
        province,
        workMode: dto.workMode,
        category: categoryOf(dto.category),
        hasAllowance: dto.hasAllowance,
        allowanceAmount: allowanceAmountOf(dto),
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
  openings?: number | null;
  allowanceAmount?: number | null;
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
  dto.openings = job.openings ?? null;
  dto.allowanceAmount = job.allowanceAmount ?? null;
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
    openings?: number | null;
    allowanceAmount?: number | null;
    requirements: string;
    skills?: string[];
    status: JobStatus;
    createdAt: Date;
    deadline?: Date | null;
    companyName: string;
    businessType: string;
    companyDescription: string;
    companyWebsiteUrl?: string;
    companySize?: string;
    companyPerks?: string[];
    companyLocation?: string;
    companyLogoObjectKey?: string | null;
    companyCoverObjectKey?: string | null;
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
  dto.openings = job.openings ?? null;
  dto.allowanceAmount = job.allowanceAmount ?? null;
  dto.requirements = job.requirements;
  dto.skills = job.skills ?? [];
  dto.status = job.status;
  dto.createdAt = job.createdAt;
  dto.deadline = job.deadline ?? null;
  dto.companyName = job.companyName;
  dto.businessType = job.businessType;
  dto.companyDescription = job.companyDescription;
  dto.companyWebsiteUrl = job.companyWebsiteUrl ?? '';
  dto.companySize = job.companySize ?? '';
  dto.companyPerks = job.companyPerks ?? [];
  dto.companyLocation = job.companyLocation ?? '';
  dto.companyLogoAvailable = Boolean(job.companyLogoObjectKey);
  dto.companyCoverAvailable = Boolean(job.companyCoverObjectKey);
  dto.saved = saved;
  return dto;
}

function toOwnedDto(
  job: {
    id: string;
    title: string;
    description: string;
    province: string;
    workMode: CompanyOwnedJobDto['workMode'];
    category: string;
    hasAllowance: boolean;
    openings?: number | null;
    allowanceAmount?: number | null;
    requirements: string;
    skills?: string[];
    status: JobStatus;
    version: number;
    deadline: Date | null;
  },
  counts: { applicantCount: number; pendingApplicantCount: number },
): CompanyOwnedJobDto {
  const dto = new CompanyOwnedJobDto();
  dto.id = job.id;
  dto.title = job.title;
  dto.description = job.description;
  dto.province = job.province;
  dto.workMode = job.workMode;
  dto.category = job.category;
  dto.hasAllowance = job.hasAllowance;
  dto.openings = job.openings ?? null;
  dto.allowanceAmount = job.allowanceAmount ?? null;
  dto.requirements = job.requirements;
  dto.skills = job.skills ?? [];
  dto.status = job.status;
  dto.version = job.version;
  dto.applicantCount = counts.applicantCount;
  dto.pendingApplicantCount = counts.pendingApplicantCount;
  dto.deadline = job.deadline;
  return dto;
}

function toCompanyItem(job: {
  id: string;
  title: string;
  status: JobStatus;
  workMode: WorkMode;
  applicantCount: number;
  pendingApplicantCount: number;
  deadline: Date | null;
}): CompanyJobItemDto {
  const dto = new CompanyJobItemDto();
  dto.id = job.id;
  dto.title = job.title;
  dto.status = job.status;
  dto.workMode = job.workMode;
  dto.applicantCount = job.applicantCount;
  dto.pendingApplicantCount = job.pendingApplicantCount;
  dto.deadline = job.deadline;
  return dto;
}

function openingsOf(value: number | null | undefined): number | null {
  const openings = value ?? null;
  if (
    openings !== null &&
    (!Number.isInteger(openings) || openings < 1 || openings > 2147483647)
  ) {
    throw new BadRequestException(
      'จำนวนรับต้องเป็นจำนวนเต็มบวก ไม่เกิน 2147483647',
    );
  }
  return openings;
}

function imageMimeType(key: string): string {
  const extension = key.split('.').pop()?.toLowerCase();
  switch (extension) {
    case 'svg':
      return 'image/svg+xml';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    default:
      return 'image/png';
  }
}

function toFeedItem(job: {
  id: string;
  title: string;
  companyName: string;
  province: string;
  workMode: JobFeedItemDto['workMode'];
  category: string;
  hasAllowance: boolean;
  openings?: number | null;
  allowanceAmount?: number | null;
  skills?: string[];
  status: JobStatus;
  createdAt: Date;
  companyLogoObjectKey?: string | null;
}): JobFeedItemDto {
  const dto = new JobFeedItemDto();
  dto.id = job.id;
  dto.title = job.title;
  dto.companyName = job.companyName;
  dto.createdAt = job.createdAt;
  dto.companyLogoAvailable = Boolean(job.companyLogoObjectKey);
  dto.province = job.province;
  dto.workMode = job.workMode;
  dto.category = job.category;
  dto.hasAllowance = job.hasAllowance;
  dto.openings = job.openings ?? null;
  dto.allowanceAmount = job.allowanceAmount ?? null;
  dto.skills = job.skills ?? [];
  dto.status = job.status;
  return dto;
}
