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
import { JobStatus, WorkMode } from '../jobs/job-enums.js';
import { Notification } from '../notifications/entities/notification.entity.js';
import { ApplicationStatus } from './application-status.js';
import {
  ALREADY_APPLIED,
  APPLICATION_NOT_FOUND,
  APPLICATION_TERMINAL_STATUS,
  INVALID_STATUS_TRANSITION,
  JOB_CLOSED,
  JOB_NOT_FOUND,
  MUST_BE_REVIEWING_BEFORE_DECISION,
  ONLY_SUBMITTED_CAN_BE_REVIEWING,
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

export interface ApplicationDetailRecord {
  id: string;
  jobId: string;
  status: ApplicationStatus;
  coverLetter: string;
  resumeObjectKey: string;
  createdAt: Date;
  updatedAt: Date;
  job: {
    id: string;
    title: string;
    companyName: string;
    province: string;
    workMode: WorkMode;
    category: string;
    hasAllowance: boolean;
  };
  timeline: {
    id: string;
    fromStatus: ApplicationStatus | null;
    toStatus: ApplicationStatus;
    createdAt: Date;
  }[];
}

export interface JobApplicantRecord {
  applicationId: string;
  fullName: string;
  university: string;
  major: string;
  status: ApplicationStatus;
  coverLetter: string;
  createdAt: Date;
}

export interface CompanyApplicantDetailRecord {
  applicationId: string;
  jobId: string;
  studentId: string;
  fullName: string;
  university: string;
  major: string;
  skills: string[];
  bio: string;
  contactLinks: Array<{
    id?: string;
    platform: string;
    label?: string;
    value: string;
  }>;
  portfolioLinks: Array<{
    id?: string;
    title: string;
    url: string;
    description?: string;
  }>;
  portfolioUrl: string | null;
  resumeFileName: string | null;
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

  async findApplicationDetail(
    applicationId: string,
    studentId: string,
  ): Promise<ApplicationDetailRecord | null> {
    const row = await this.dataSource
      .getRepository(Application)
      .createQueryBuilder('app')
      .innerJoin(Job, 'job', 'job.id = app.jobId')
      .innerJoin(CompanyProfile, 'company', 'company.id = job.companyId')
      .where('app.id = :applicationId AND app.studentId = :studentId', {
        applicationId,
        studentId,
      })
      .select('app.id', 'id')
      .addSelect('app.jobId', 'jobId')
      .addSelect('app.status', 'status')
      .addSelect('app.coverLetter', 'coverLetter')
      .addSelect('app.resumeObjectKey', 'resumeObjectKey')
      .addSelect('app.createdAt', 'createdAt')
      .addSelect('app.updatedAt', 'updatedAt')
      .addSelect('job.title', 'jobTitle')
      .addSelect('job.province', 'province')
      .addSelect('job.workMode', 'workMode')
      .addSelect('job.category', 'category')
      .addSelect('job.hasAllowance', 'hasAllowance')
      .addSelect('company.name', 'companyName')
      .getRawOne();

    if (!row) {
      return null;
    }

    const events = await this.dataSource
      .getRepository(ApplicationStatusEvent)
      .find({
        where: { applicationId },
        order: { createdAt: 'ASC' },
      });

    return {
      id: row.id as string,
      jobId: row.jobId as string,
      status: row.status as ApplicationStatus,
      coverLetter: row.coverLetter as string,
      resumeObjectKey: row.resumeObjectKey as string,
      createdAt: new Date(row.createdAt as string | Date),
      updatedAt: new Date(row.updatedAt as string | Date),
      job: {
        id: row.jobId as string,
        title: row.jobTitle as string,
        companyName: row.companyName as string,
        province: row.province as string,
        workMode: row.workMode as WorkMode,
        category: row.category as string,
        hasAllowance: Boolean(row.hasAllowance),
      },
      timeline: events.map((event) => ({
        id: event.id,
        fromStatus: event.fromStatus,
        toStatus: event.toStatus,
        createdAt: event.createdAt,
      })),
    };
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

  async findCompanyProfileByUserId(
    userId: string,
  ): Promise<CompanyProfile | null> {
    return this.dataSource.getRepository(CompanyProfile).findOne({
      where: { userId },
    });
  }

  async findJobById(jobId: string): Promise<Job | null> {
    return this.dataSource.getRepository(Job).findOne({
      where: { id: jobId },
    });
  }

  async listJobApplicants(jobId: string): Promise<JobApplicantRecord[]> {
    const rows = await this.dataSource
      .getRepository(Application)
      .createQueryBuilder('app')
      .innerJoin(StudentProfile, 'student', 'student.id = app.studentId')
      .where('app.jobId = :jobId', { jobId })
      .select('app.id', 'applicationId')
      .addSelect('student.fullName', 'fullName')
      .addSelect('student.university', 'university')
      .addSelect('student.major', 'major')
      .addSelect('app.status', 'status')
      .addSelect('app.coverLetter', 'coverLetter')
      .addSelect('app.createdAt', 'createdAt')
      .orderBy('app.createdAt', 'DESC')
      .getRawMany();

    return rows.map((row) => ({
      applicationId: row.applicationId as string,
      fullName: (row.fullName as string) ?? '',
      university: (row.university as string) ?? '',
      major: (row.major as string) ?? '',
      status: row.status as ApplicationStatus,
      coverLetter: (row.coverLetter as string) ?? '',
      createdAt: new Date(row.createdAt as string | Date),
    }));
  }

  async findCompanyApplicantDetail(
    jobId: string,
    applicationId: string,
  ): Promise<CompanyApplicantDetailRecord | null> {
    const application = await this.dataSource
      .getRepository(Application)
      .findOne({
        where: { id: applicationId, jobId },
      });
    if (!application) {
      return null;
    }

    const student = await this.dataSource
      .getRepository(StudentProfile)
      .findOne({
        where: { id: application.studentId },
      });

    return {
      applicationId: application.id,
      jobId: application.jobId,
      studentId: application.studentId,
      fullName: student?.fullName ?? '',
      university: student?.university ?? '',
      major: student?.major ?? '',
      skills: Array.isArray(student?.skills) ? student.skills : [],
      bio: student?.bio ?? '',
      contactLinks: Array.isArray(student?.contactLinks) ? student.contactLinks : [],
      portfolioLinks: Array.isArray(student?.portfolioLinks) ? student.portfolioLinks : [],
      portfolioUrl: student?.portfolioUrl ?? null,
      resumeFileName: student?.resumeFileName ?? null,
      status: application.status,
      coverLetter: application.coverLetter,
      resumeObjectKey: application.resumeObjectKey,
      createdAt: application.createdAt,
      updatedAt: application.updatedAt,
    };
  }

  async updateApplicationStatus(params: {
    jobId: string;
    applicationId: string;
    newStatus: ApplicationStatus;
    jobTitle: string;
    actorUserId: string;
  }): Promise<Application> {
    return this.dataSource.transaction(async (manager) => {
      const application = await manager
        .createQueryBuilder(Application, 'app')
        .setLock('pessimistic_write')
        .where('app.id = :applicationId AND app.jobId = :jobId', {
          applicationId: params.applicationId,
          jobId: params.jobId,
        })
        .getOne();

      if (!application) {
        throw new NotFoundException(APPLICATION_NOT_FOUND);
      }

      if (
        application.status === ApplicationStatus.Accepted ||
        application.status === ApplicationStatus.Rejected
      ) {
        throw new BadRequestException(APPLICATION_TERMINAL_STATUS);
      }

      if (params.newStatus === ApplicationStatus.Reviewing) {
        if (application.status !== ApplicationStatus.Submitted) {
          throw new BadRequestException(ONLY_SUBMITTED_CAN_BE_REVIEWING);
        }
      } else if (
        params.newStatus === ApplicationStatus.Accepted ||
        params.newStatus === ApplicationStatus.Rejected
      ) {
        if (application.status !== ApplicationStatus.Reviewing) {
          throw new BadRequestException(MUST_BE_REVIEWING_BEFORE_DECISION);
        }
      } else {
        throw new BadRequestException(INVALID_STATUS_TRANSITION);
      }

      const fromStatus = application.status;
      application.status = params.newStatus;
      const updatedApplication = await manager.save(Application, application);

      const statusEvent = manager.create(ApplicationStatusEvent, {
        applicationId: application.id,
        fromStatus,
        toStatus: params.newStatus,
        actorUserId: params.actorUserId,
      });
      await manager.save(ApplicationStatusEvent, statusEvent);

      let notificationMessage: string;
      if (params.newStatus === ApplicationStatus.Reviewing) {
        notificationMessage = `สถานะใบสมัครงาน ${params.jobTitle} ปรับเป็น Reviewing`;
      } else if (params.newStatus === ApplicationStatus.Accepted) {
        notificationMessage = `สถานะใบสมัครงาน ${params.jobTitle} ผ่านการคัดเลือก (Accepted)`;
      } else {
        notificationMessage = `สถานะใบสมัครงาน ${params.jobTitle} ไม่ผ่านการคัดเลือก (Rejected)`;
      }

      const notification = manager.create(Notification, {
        studentId: application.studentId,
        applicationId: application.id,
        message: notificationMessage,
        readAt: null,
      });
      await manager.save(Notification, notification);

      return updatedApplication;
    });
  }

  async updateApplicationStatusToReviewing(params: {
    jobId: string;
    applicationId: string;
    jobTitle: string;
    actorUserId: string;
  }): Promise<Application> {
    return this.updateApplicationStatus({
      ...params,
      newStatus: ApplicationStatus.Reviewing,
    });
  }
}

