import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, EntityManager, QueryFailedError } from 'typeorm';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { Major } from '../majors/major.entity.js';
import { StudentDocument, StudentDocumentType } from '../students/student-document.entity.js';
import { University } from '../universities/university.entity.js';
import { Job } from '../jobs/entities/job.entity.js';
import { InterviewMode, JobStatus, WorkMode } from '../jobs/job-enums.js';
import { Notification } from '../notifications/entities/notification.entity.js';
import { ApplicationStatus } from './application-status.js';
import {
  ALREADY_APPLIED,
  APPLICATION_NOT_FOUND,
  APPLICATION_TERMINAL_STATUS,
  INVALID_STATUS_TRANSITION,
  JOB_CLOSED,
  JOB_NOT_FOUND,
  ACCEPT_REQUIRES_INTERVIEW,
  MUST_BE_REVIEWING_BEFORE_DECISION,
  ONLY_SUBMITTED_CAN_BE_REVIEWING,
} from './applications.constants.js';
import { ApplicationStatusEvent } from './entities/application-status-event.entity.js';
import { Application } from './entities/application.entity.js';
import {
  assertCanCompleteExam,
  assertCanPassExam,
  assertCanSetExam,
  assertCanSetInterview,
} from './selection-link.js';

export interface ApplyJobParams {
  studentId: string;
  jobId: string;
  coverLetter: string;
  resumeObjectKey: string;
  resumeFileName: string | null;
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
  examUrl: string | null;
  examDeadline: Date | null;
  examCompletedAt: Date | null;
  examPassedAt: Date | null;
  interviewUrl: string | null;
  interviewStartsAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface ApplicationDetailRecord {
  id: string;
  jobId: string;
  status: ApplicationStatus;
  coverLetter: string;
  resumeObjectKey: string;
  examUrl: string | null;
  examDeadline: Date | null;
  examCompletedAt: Date | null;
  examPassedAt: Date | null;
  interviewUrl: string | null;
  interviewStartsAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  job: {
    id: string;
    title: string;
    companyName: string;
    province: string;
    workMode: WorkMode;
    interviewMode: InterviewMode;
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
  avatarObjectKey: string | null;
  status: ApplicationStatus;
  coverLetter: string;
  examUrl: string | null;
  examDeadline: Date | null;
  examCompletedAt: Date | null;
  examPassedAt: Date | null;
  interviewUrl: string | null;
  interviewStartsAt: Date | null;
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
  avatarObjectKey: string | null;
  status: ApplicationStatus;
  coverLetter: string;
  resumeObjectKey: string;
  examUrl: string | null;
  examDeadline: Date | null;
  examCompletedAt: Date | null;
  examPassedAt: Date | null;
  interviewUrl: string | null;
  interviewStartsAt: Date | null;
  interviewMode: InterviewMode;
  createdAt: Date;
  updatedAt: Date;
  documents: Array<{ id: string; type: string; fileName: string }>;
}

@Injectable()
export class ApplicationsRepository {
  constructor(private readonly dataSource: DataSource) {}

  findStudentCv(studentId: string): Promise<StudentDocument | null> {
    return this.dataSource.getRepository(StudentDocument).findOne({
      where: { studentId, type: StudentDocumentType.Cv },
    });
  }

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
      .addSelect('app.examUrl', 'examUrl')
      .addSelect('app.examDeadline', 'examDeadline')
      .addSelect('app.examCompletedAt', 'examCompletedAt')
      .addSelect('app.examPassedAt', 'examPassedAt')
      .addSelect('app.interviewUrl', 'interviewUrl')
      .addSelect('app.interviewStartsAt', 'interviewStartsAt')
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
      ...selectionFromRow(row),
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
      .addSelect('app.examUrl', 'examUrl')
      .addSelect('app.examDeadline', 'examDeadline')
      .addSelect('app.examCompletedAt', 'examCompletedAt')
      .addSelect('app.examPassedAt', 'examPassedAt')
      .addSelect('app.interviewUrl', 'interviewUrl')
      .addSelect('app.interviewStartsAt', 'interviewStartsAt')
      .addSelect('app.createdAt', 'createdAt')
      .addSelect('app.updatedAt', 'updatedAt')
      .addSelect('job.title', 'jobTitle')
      .addSelect('job.province', 'province')
      .addSelect('job.workMode', 'workMode')
      .addSelect('job.interviewMode', 'interviewMode')
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
      ...selectionFromRow(row),
      createdAt: new Date(row.createdAt as string | Date),
      updatedAt: new Date(row.updatedAt as string | Date),
      job: {
        id: row.jobId as string,
        title: row.jobTitle as string,
        companyName: row.companyName as string,
        province: row.province as string,
        workMode: row.workMode as WorkMode,
        interviewMode: row.interviewMode as InterviewMode,
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
    resumeFileName: string | null;
    actorUserId: string;
  }): Promise<Application> {
    try {
      return await this.dataSource.transaction(async (manager) => {
        await manager
          .createQueryBuilder(StudentProfile, 'student')
          .setLock('pessimistic_write')
          .where('student.id = :studentId', { studentId: params.studentId })
          .getOne();
        const currentCv = await manager.findOne(StudentDocument, {
          where: { studentId: params.studentId, type: StudentDocumentType.Cv },
        });
        const resumeObjectKey = currentCv?.objectKey ?? params.resumeObjectKey;
        const resumeFileName = currentCv?.fileName ?? params.resumeFileName;
        if (!resumeObjectKey) throw new BadRequestException('ต้องอัปโหลด CV ก่อนสมัครงาน');
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
          resumeObjectKey,
          resumeFileName,
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
      .leftJoin(University, 'university', 'university.id = student.universityId')
      .leftJoin(Major, 'major', 'major.id = student.majorId')
      .where('app.jobId = :jobId', { jobId })
      .select('app.id', 'applicationId')
      .addSelect('student.fullName', 'fullName')
      .addSelect(`COALESCE(student.customUniversityName, university.nameTh, '')`, 'university')
      .addSelect(`COALESCE(student.customMajorName, major.nameTh, '')`, 'major')
      .addSelect('student.avatarObjectKey', 'avatarObjectKey')
      .addSelect('app.status', 'status')
      .addSelect('app.coverLetter', 'coverLetter')
      .addSelect('app.examUrl', 'examUrl')
      .addSelect('app.examDeadline', 'examDeadline')
      .addSelect('app.examCompletedAt', 'examCompletedAt')
      .addSelect('app.examPassedAt', 'examPassedAt')
      .addSelect('app.interviewUrl', 'interviewUrl')
      .addSelect('app.interviewStartsAt', 'interviewStartsAt')
      .addSelect('app.createdAt', 'createdAt')
      .orderBy('app.createdAt', 'DESC')
      .getRawMany();

    return rows.map((row) => ({
      applicationId: row.applicationId as string,
      fullName: (row.fullName as string) ?? '',
      university: (row.university as string) ?? '',
      major: (row.major as string) ?? '',
      avatarObjectKey: (row.avatarObjectKey as string) ?? null,
      status: row.status as ApplicationStatus,
      coverLetter: (row.coverLetter as string) ?? '',
      ...selectionFromRow(row),
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
    const university = student?.universityId
      ? await this.dataSource.getRepository(University).findOne({ where: { id: student.universityId } })
      : null;
    const major = student?.majorId
      ? await this.dataSource.getRepository(Major).findOne({ where: { id: student.majorId } })
      : null;
    const job = await this.dataSource.getRepository(Job).findOne({
      where: { id: jobId },
    });
    const documents = await this.listApplicantDocuments(jobId, applicationId);
    const appliedCvName = documents.find((doc) => doc.id === 'application-cv')?.fileName ?? null;

    return {
      applicationId: application.id,
      jobId: application.jobId,
      studentId: application.studentId,
      fullName: student?.fullName ?? '',
      university: student?.customUniversityName ?? university?.nameTh ?? '',
      major: student?.customMajorName ?? major?.nameTh ?? '',
      skills: Array.isArray(student?.skills) ? student.skills : [],
      bio: student?.bio ?? '',
      contactLinks: Array.isArray(student?.contactLinks)
        ? student.contactLinks
        : [],
      portfolioLinks: Array.isArray(student?.portfolioLinks)
        ? student.portfolioLinks
        : [],
      portfolioUrl: student?.portfolioUrl ?? null,
      resumeFileName: appliedCvName,
      avatarObjectKey: student?.avatarObjectKey ?? null,
      status: application.status,
      coverLetter: application.coverLetter,
      resumeObjectKey: application.resumeObjectKey,
      examUrl: application.examUrl,
      examDeadline: application.examDeadline,
      examCompletedAt: application.examCompletedAt,
      examPassedAt: application.examPassedAt,
      interviewUrl: application.interviewUrl,
      interviewStartsAt: application.interviewStartsAt,
      interviewMode: job?.interviewMode ?? InterviewMode.Online,
      createdAt: application.createdAt,
      updatedAt: application.updatedAt,
      documents,
    };
  }

  async listApplicantDocuments(jobId: string, applicationId: string) {
    const application = await this.dataSource.getRepository(Application).findOne({ where: { id: applicationId, jobId } });
    if (!application) return [];
    const docs = await this.dataSource.getRepository(StudentDocument).find({
      where: { studentId: application.studentId }, order: { createdAt: 'ASC' },
    });
    const cv = docs.find((doc) => doc.objectKey === application.resumeObjectKey);
    return [
      { id: 'application-cv', type: StudentDocumentType.Cv, fileName: application.resumeFileName ?? cv?.fileName ?? 'CV used for application.pdf', available: true },
      ...docs.filter((doc) => doc.type !== StudentDocumentType.Cv).map((doc) => ({ id: doc.id, type: doc.type, fileName: doc.fileName, available: true })),
    ];
  }

  async findApplicantDocument(jobId: string, applicationId: string, documentId: string) {
    const application = await this.dataSource.getRepository(Application).findOne({ where: { id: applicationId, jobId } });
    if (!application) return null;
    if (documentId === 'application-cv') {
      const cv = await this.dataSource.getRepository(StudentDocument).findOne({ where: { studentId: application.studentId, objectKey: application.resumeObjectKey } });
      return { objectKey: application.resumeObjectKey, fileName: application.resumeFileName ?? cv?.fileName ?? 'CV used for application.pdf' };
    }
    const document = await this.dataSource.getRepository(StudentDocument).findOne({ where: { id: documentId, studentId: application.studentId } });
    return document ? { objectKey: document.objectKey, fileName: document.fileName } : null;
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
        if (
          params.newStatus === ApplicationStatus.Accepted &&
          !application.interviewStartsAt
        ) {
          throw new BadRequestException(ACCEPT_REQUIRES_INTERVIEW);
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

  async setExamLink(params: {
    jobId: string;
    applicationId: string;
    url: string;
    deadline: Date;
    jobTitle: string;
  }): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const application = await this.lockApplication(
        manager,
        params.jobId,
        params.applicationId,
      );
      assertCanSetExam(application);
      application.examUrl = params.url;
      application.examDeadline = params.deadline;
      await manager.save(Application, application);
      await this.notifyStudent(
        manager,
        application,
        `บริษัทส่งลิงก์ข้อสอบสำหรับงาน ${params.jobTitle}`,
      );
    });
  }

  async passExam(params: {
    jobId: string;
    applicationId: string;
    jobTitle: string;
  }): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const application = await this.lockApplication(
        manager,
        params.jobId,
        params.applicationId,
      );
      assertCanPassExam(application);
      application.examPassedAt = new Date();
      await manager.save(Application, application);
      await this.notifyStudent(
        manager,
        application,
        `บริษัทตรวจว่าข้อสอบผ่านแล้วสำหรับงาน ${params.jobTitle}`,
      );
    });
  }

  async setInterviewLink(params: {
    jobId: string;
    applicationId: string;
    url: string | null;
    startsAt: Date;
    jobTitle: string;
  }): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const application = await this.lockApplication(
        manager,
        params.jobId,
        params.applicationId,
      );
      assertCanSetInterview(application);
      application.interviewUrl = params.url;
      application.interviewStartsAt = params.startsAt;
      await manager.save(Application, application);
      await this.notifyStudent(
        manager,
        application,
        params.url
          ? `บริษัทส่งลิงก์นัดสัมภาษณ์สำหรับงาน ${params.jobTitle}`
          : `บริษัทนัดสัมภาษณ์ที่สำนักงานสำหรับงาน ${params.jobTitle}`,
      );
    });
  }

  async completeExam(params: {
    applicationId: string;
    studentId: string;
  }): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const application = await manager
        .createQueryBuilder(Application, 'app')
        .setLock('pessimistic_write')
        .where('app.id = :applicationId AND app.studentId = :studentId', params)
        .getOne();
      if (!application) {
        throw new NotFoundException(APPLICATION_NOT_FOUND);
      }
      assertCanCompleteExam(application, new Date());
      application.examCompletedAt = new Date();
      await manager.save(Application, application);
    });
  }

  private async lockApplication(
    manager: EntityManager,
    jobId: string,
    applicationId: string,
  ): Promise<Application> {
    const application = await manager
      .createQueryBuilder(Application, 'app')
      .setLock('pessimistic_write')
      .where('app.id = :applicationId AND app.jobId = :jobId', {
        applicationId,
        jobId,
      })
      .getOne();
    if (!application) {
      throw new NotFoundException(APPLICATION_NOT_FOUND);
    }
    return application;
  }

  private async notifyStudent(
    manager: EntityManager,
    application: Application,
    message: string,
  ): Promise<void> {
    await manager.save(
      Notification,
      manager.create(Notification, {
        studentId: application.studentId,
        applicationId: application.id,
        message,
        readAt: null,
      }),
    );
  }
}

function selectionFromRow(row: Record<string, unknown>): {
  examUrl: string | null;
  examDeadline: Date | null;
  examCompletedAt: Date | null;
  examPassedAt: Date | null;
  interviewUrl: string | null;
  interviewStartsAt: Date | null;
} {
  return {
    examUrl: (row.examUrl as string | null) ?? null,
    examDeadline: asDate(row.examDeadline),
    examCompletedAt: asDate(row.examCompletedAt),
    examPassedAt: asDate(row.examPassedAt),
    interviewUrl: (row.interviewUrl as string | null) ?? null,
    interviewStartsAt: asDate(row.interviewStartsAt),
  };
}

function asDate(value: unknown): Date | null {
  if (value == null || value === '') return null;
  const date = value instanceof Date ? value : new Date(String(value));
  return Number.isNaN(date.getTime()) ? null : date;
}
