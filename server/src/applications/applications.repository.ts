import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, QueryFailedError } from 'typeorm';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { Job } from '../jobs/entities/job.entity.js';
import { JobStatus } from '../jobs/job-enums.js';
import { ApplicationStatus } from './application-status.js';
import {
  ALREADY_APPLIED,
  JOB_CLOSED,
  JOB_NOT_FOUND,
} from './applications.constants.js';
import { ApplicationStatusEvent } from './entities/application-status-event.entity.js';
import { Application } from './entities/application.entity.js';

export interface ApplyJobParams {
  studentId: string;
  jobId: string;
  coverLetter: string;
  resumeObjectKey: string;
  actorUserId: string;
}

export interface MyApplicationRecord {
  id: string;
  jobId: string;
  jobTitle: string;
  companyName: string;
  status: ApplicationStatus;
  coverLetter: string;
  resumeObjectKey: string;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class ApplicationsRepository {
  constructor(private readonly dataSource: DataSource) {}

  async listStudentApplications(
    studentId: string,
  ): Promise<MyApplicationRecord[]> {
    const rows = await this.dataSource
      .getRepository(Application)
      .createQueryBuilder('app')
      .innerJoin(Job, 'job', 'job.id = app.jobId')
      .innerJoin(CompanyProfile, 'company', 'company.id = job.companyId')
      .where('app.studentId = :studentId', { studentId })
      .select('app.id', 'id')
      .addSelect('app.jobId', 'jobId')
      .addSelect('job.title', 'jobTitle')
      .addSelect('company.name', 'companyName')
      .addSelect('app.status', 'status')
      .addSelect('app.coverLetter', 'coverLetter')
      .addSelect('app.resumeObjectKey', 'resumeObjectKey')
      .addSelect('app.createdAt', 'createdAt')
      .addSelect('app.updatedAt', 'updatedAt')
      .orderBy('app.createdAt', 'DESC')
      .getRawMany();

    return rows.map((row) => ({
      id: row.id as string,
      jobId: row.jobId as string,
      jobTitle: row.jobTitle as string,
      companyName: row.companyName as string,
      status: row.status as ApplicationStatus,
      coverLetter: row.coverLetter as string,
      resumeObjectKey: row.resumeObjectKey as string,
      createdAt: new Date(row.createdAt as string | Date),
      updatedAt: new Date(row.updatedAt as string | Date),
    }));
  }

  async findStudentProfileByUserId(
    userId: string,
  ): Promise<StudentProfile | null> {
    return this.dataSource.getRepository(StudentProfile).findOne({
      where: { userId },
    });
  }

  async findApplication(
    studentId: string,
    jobId: string,
  ): Promise<Application | null> {
    return this.dataSource.getRepository(Application).findOne({
      where: { studentId, jobId },
    });
  }

  async applyJob(params: {
    studentId: string;
    jobId: string;
    coverLetter: string;
    resumeObjectKey: string;
    actorUserId: string;
  }): Promise<Application> {
    try {
      return await this.dataSource.transaction(async (manager) => {
        const job = await manager
          .createQueryBuilder(Job, 'job')
          .setLock('pessimistic_write')
          .where('job.id = :jobId', { jobId: params.jobId })
          .getOne();

        if (!job) {
          throw new NotFoundException(JOB_NOT_FOUND);
        }

        if (job.status !== JobStatus.Open) {
          throw new BadRequestException(JOB_CLOSED);
        }

        const existing = await manager.findOne(Application, {
          where: { studentId: params.studentId, jobId: params.jobId },
        });
        if (existing) {
          throw new ConflictException(ALREADY_APPLIED);
        }

        const application = manager.create(Application, {
          studentId: params.studentId,
          jobId: params.jobId,
          coverLetter: params.coverLetter,
          resumeObjectKey: params.resumeObjectKey,
          status: ApplicationStatus.Submitted,
          version: 1,
        });
        const savedApplication = await manager.save(Application, application);

        const statusEvent = manager.create(ApplicationStatusEvent, {
          applicationId: savedApplication.id,
          fromStatus: null,
          toStatus: ApplicationStatus.Submitted,
          actorUserId: params.actorUserId,
        });
        await manager.save(ApplicationStatusEvent, statusEvent);

        return savedApplication;
      });
    } catch (error) {
      if (
        error instanceof QueryFailedError &&
        (error as { code?: string }).code === '23505'
      ) {
        throw new ConflictException(ALREADY_APPLIED);
      }
      throw error;
    }
  }
}
