import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { CreateJobDto } from './dto/create-job.dto.js';
import { JobDetailDto } from './dto/job-detail.dto.js';
import { JobDto } from './dto/job.dto.js';
import { JobFeedItemDto } from './dto/job-feed-item.dto.js';
import { JobFeedQueryDto } from './dto/job-feed-query.dto.js';
import { JobStatus } from './job-enums.js';
import { JobsRepository } from './jobs.repository.js';

const COMPANY_ONLY = 'เฉพาะบริษัทเท่านั้น';
const COMPANY_NOT_FOUND = 'ไม่พบโปรไฟล์บริษัท';
const STUDENT_ONLY = 'เฉพาะนักศึกษาเท่านั้น';
const JOB_NOT_FOUND = 'ไม่พบประกาศ';
const STUDENT_NOT_FOUND = 'ไม่พบโปรไฟล์';

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
    });
    return toDto(job);
  }

  async listOpen(
    user: AuthUser,
    query: JobFeedQueryDto,
  ): Promise<JobFeedItemDto[]> {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
    const jobs = await this.jobsRepository.findOpen({
      search: query.search,
      province: query.province,
      workMode: query.workMode,
      category: query.category,
      hasAllowance: query.hasAllowance,
    });
    return jobs.map(toFeedItem);
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

  async listSaved(user: AuthUser): Promise<JobFeedItemDto[]> {
    const studentId = await this.requireStudentId(user);
    const jobs = await this.jobsRepository.listSaved(studentId);
    return jobs.map(toFeedItem);
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
  dto.status = job.status;
  dto.companyName = job.companyName;
  dto.businessType = job.businessType;
  dto.companyDescription = job.companyDescription;
  dto.saved = saved;
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
  dto.status = job.status;
  return dto;
}
