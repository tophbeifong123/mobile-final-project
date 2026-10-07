import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { StorageService } from '../storage/storage.service.js';
import {
  APPLICATION_NOT_FOUND,
  COMPANY_ONLY,
  COMPANY_PROFILE_NOT_FOUND,
  COVER_LETTER_REQUIRED,
  INVALID_STATUS_TRANSITION,
  JOB_NOT_FOUND,
  NOT_YOUR_JOB,
  PROFILE_NOT_FOUND,
  STUDENT_ONLY,
} from './applications.constants.js';
import {
  ApplicationsRepository,
  type CompanyApplicantDetailRecord,
} from './applications.repository.js';
import { ApplicationStatus } from './application-status.js';
import { ApplicantDetailDto } from './dto/applicant-detail.dto.js';
import { ApplicationDetailDto } from './dto/application-detail.dto.js';
import { ApplicationResponseDto } from './dto/application-response.dto.js';
import { ApplyJobDto } from './dto/apply-job.dto.js';
import { JobApplicantItemDto } from './dto/job-applicant-item.dto.js';
import { MyApplicationItemDto } from './dto/my-application-item.dto.js';
import { UpdateApplicationStatusDto } from './dto/update-application-status.dto.js';
import { Application } from './entities/application.entity.js';
import { InterviewMode } from '../jobs/job-enums.js';
import { selectApplicationDocuments } from './application-document-selection.js';
import { SetExamLinkDto } from './dto/set-exam-link.dto.js';
import { SetInterviewLinkDto } from './dto/set-interview-link.dto.js';
import {
  assertFutureInstant,
  assertPublicHttpUrl,
  interviewUrlForMode,
} from './selection-link.js';

@Injectable()
export class ApplicationsService {
  constructor(
    private readonly applicationsRepository: ApplicationsRepository,
    private readonly storageService: StorageService,
  ) {}

  async getDetail(
    user: AuthUser,
    applicationId: string,
  ): Promise<ApplicationDetailDto> {
    this.assertStudent(user);

    const profile =
      await this.applicationsRepository.findStudentProfileByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    const application = await this.applicationsRepository.findApplicationDetail(
      applicationId,
      profile.id,
    );
    if (!application) {
      throw new NotFoundException(APPLICATION_NOT_FOUND);
    }

    return {
      id: application.id,
      jobId: application.jobId,
      job: {
        id: application.job.id,
        title: application.job.title,
        companyName: application.job.companyName,
        province: application.job.province,
        workMode: application.job.workMode,
        interviewMode: application.job.interviewMode,
        category: application.job.category,
        hasAllowance: application.job.hasAllowance,
      },
      status: application.status,
      coverLetter: application.coverLetter,
      resumeObjectKey: application.resumeObjectKey,
      ...selectionResponse(application),
      createdAt: application.createdAt.toISOString(),
      updatedAt: application.updatedAt.toISOString(),
      timeline: application.timeline.map((event) => ({
        id: event.id,
        fromStatus: event.fromStatus,
        toStatus: event.toStatus,
        createdAt: event.createdAt.toISOString(),
      })),
      documents: application.documents ?? [],
    };
  }

  async getMine(user: AuthUser): Promise<MyApplicationItemDto[]> {
    this.assertStudent(user);

    const profile =
      await this.applicationsRepository.findStudentProfileByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    const applications =
      await this.applicationsRepository.listStudentApplications(profile.id);

    return applications.map((item) => ({
      id: item.id,
      jobId: item.jobId,
      jobTitle: item.jobTitle,
      companyName: item.companyName,
      status: item.status,
      coverLetter: item.coverLetter,
      resumeObjectKey: item.resumeObjectKey,
      ...selectionResponse(item),
      createdAt: item.createdAt.toISOString(),
      updatedAt: item.updatedAt.toISOString(),
    }));
  }

  async apply(
    user: AuthUser,
    jobId: string,
    dto: ApplyJobDto,
  ): Promise<ApplicationResponseDto> {
    this.assertStudent(user);

    const coverLetter = dto.coverLetter?.trim();
    if (!coverLetter) {
      throw new BadRequestException(COVER_LETTER_REQUIRED);
    }

    const profile =
      await this.applicationsRepository.findStudentProfileByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    const documents = await this.applicationsRepository.findStudentDocuments(
      profile.id,
    );
    const [cv] = selectApplicationDocuments(documents, dto.documentIds);

    const application = await this.applicationsRepository.applyJob({
      studentId: profile.id,
      jobId,
      coverLetter,
      resumeObjectKey: cv.objectKey,
      resumeFileName: cv.fileName,
      documentIds: dto.documentIds ?? [],
      actorUserId: user.userId,
    });

    return this.toResponseDto(application);
  }

  async getJobApplicants(
    user: AuthUser,
    jobId: string,
  ): Promise<JobApplicantItemDto[]> {
    this.assertCompany(user);

    const companyProfile =
      await this.applicationsRepository.findCompanyProfileByUserId(user.userId);
    if (!companyProfile) {
      throw new NotFoundException(COMPANY_PROFILE_NOT_FOUND);
    }

    const job = await this.applicationsRepository.findJobById(jobId);
    if (!job) {
      throw new NotFoundException(JOB_NOT_FOUND);
    }

    if (job.companyId !== companyProfile.id) {
      throw new ForbiddenException(NOT_YOUR_JOB);
    }

    const applicants =
      await this.applicationsRepository.listJobApplicants(jobId);

    return applicants.map((app) => ({
      applicationId: app.applicationId,
      fullName: app.fullName,
      university: app.university,
      major: app.major,
      avatarObjectKey: app.avatarObjectKey,
      status: app.status,
      coverLetter: app.coverLetter,
      ...selectionResponse(app),
      createdAt: app.createdAt.toISOString(),
    }));
  }

  async getApplicantDetail(
    user: AuthUser,
    jobId: string,
    applicationId: string,
  ): Promise<ApplicantDetailDto> {
    this.assertCompany(user);

    const companyProfile =
      await this.applicationsRepository.findCompanyProfileByUserId(user.userId);
    if (!companyProfile) {
      throw new NotFoundException(COMPANY_PROFILE_NOT_FOUND);
    }

    const job = await this.applicationsRepository.findJobById(jobId);
    if (!job) {
      throw new NotFoundException(JOB_NOT_FOUND);
    }

    if (job.companyId !== companyProfile.id) {
      throw new ForbiddenException(NOT_YOUR_JOB);
    }

    const detail = await this.applicationsRepository.findCompanyApplicantDetail(
      jobId,
      applicationId,
    );
    if (!detail) {
      throw new NotFoundException(APPLICATION_NOT_FOUND);
    }

    return this.toApplicantDetailDto(detail);
  }

  async getApplicantResume(
    user: AuthUser,
    jobId: string,
    applicationId: string,
  ): Promise<Buffer> {
    // Reuse company/job/application ownership checks; never read the current student resume.
    const detail = await this.getApplicantDetail(user, jobId, applicationId);
    if (!detail.resumeObjectKey)
      throw new NotFoundException('ไม่พบไฟล์ Resume ของใบสมัคร');
    let buffer: Buffer | null;
    try {
      buffer = await this.storageService.get(detail.resumeObjectKey);
    } catch {
      throw new ServiceUnavailableException(
        'เปิดไฟล์ Resume ไม่สำเร็จ กรุณาลองใหม่',
      );
    }
    if (
      !buffer ||
      buffer.length < 4 ||
      buffer.subarray(0, 4).toString() !== '%PDF'
    ) {
      throw new NotFoundException('ไม่พบไฟล์ Resume PDF ของใบสมัคร');
    }
    return buffer;
  }

  async getApplicantAvatar(
    user: AuthUser,
    jobId: string,
    applicationId: string,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    this.assertCompany(user);
    const detail = await this.getApplicantDetail(user, jobId, applicationId);
    if (!detail.avatarObjectKey) {
      throw new NotFoundException('ไม่พบรูปโปรไฟล์ผู้สมัคร');
    }
    const buffer = await this.storageService.get(detail.avatarObjectKey);
    if (!buffer) {
      throw new NotFoundException('ไม่พบรูปโปรไฟล์ผู้สมัคร');
    }
    const ext = detail.avatarObjectKey.split('.').pop()?.toLowerCase();
    let mimeType = 'image/png';
    if (ext === 'jpg' || ext === 'jpeg') mimeType = 'image/jpeg';
    else if (ext === 'webp') mimeType = 'image/webp';
    else if (ext === 'svg') mimeType = 'image/svg+xml';
    else if (ext === 'gif') mimeType = 'image/gif';

    return { buffer, mimeType };
  }

  async getApplicantDocument(
    user: AuthUser,
    jobId: string,
    applicationId: string,
    documentId: string,
  ) {
    this.assertCompany(user);
    const detail = await this.getApplicantDetail(user, jobId, applicationId);
    const doc = detail.documents.find((item) => item.id === documentId);
    if (!doc) throw new NotFoundException('ไม่พบเอกสารผู้สมัคร');
    const stored = await this.applicationsRepository.findApplicantDocument(
      jobId,
      applicationId,
      documentId,
    );
    if (!stored) throw new NotFoundException('ไม่พบไฟล์เอกสารผู้สมัคร');
    return this.readDocumentPdf(stored);
  }

  async getStudentApplicationDocument(
    user: AuthUser,
    applicationId: string,
    documentId: string,
  ) {
    const detail = await this.getDetail(user, applicationId);
    if (!detail.documents.some((doc) => doc.id === documentId))
      throw new NotFoundException('ไม่พบเอกสารใบสมัคร');
    const stored = await this.applicationsRepository.findApplicantDocument(
      detail.jobId,
      applicationId,
      documentId,
    );
    if (!stored) throw new NotFoundException('ไม่พบเอกสารใบสมัคร');
    return this.readDocumentPdf(stored);
  }

  private async readDocumentPdf(stored: {
    objectKey: string;
    fileName: string;
  }) {
    let buffer: Buffer | null;
    try {
      buffer = await this.storageService.get(stored.objectKey);
    } catch {
      throw new ServiceUnavailableException('เปิดไฟล์ไม่สำเร็จ กรุณาลองใหม่');
    }
    if (
      !buffer ||
      buffer.length < 4 ||
      buffer.subarray(0, 4).toString() !== '%PDF'
    ) {
      throw new NotFoundException('ไม่พบไฟล์เอกสาร PDF');
    }
    return { buffer, fileName: stored.fileName };
  }

  async updateApplicantStatus(
    user: AuthUser,
    jobId: string,
    applicationId: string,
    dto: UpdateApplicationStatusDto,
  ): Promise<ApplicantDetailDto> {
    this.assertCompany(user);

    const companyProfile =
      await this.applicationsRepository.findCompanyProfileByUserId(user.userId);
    if (!companyProfile) {
      throw new NotFoundException(COMPANY_PROFILE_NOT_FOUND);
    }

    const job = await this.applicationsRepository.findJobById(jobId);
    if (!job) {
      throw new NotFoundException(JOB_NOT_FOUND);
    }

    if (job.companyId !== companyProfile.id) {
      throw new ForbiddenException(NOT_YOUR_JOB);
    }

    if (
      dto.status !== ApplicationStatus.Reviewing &&
      dto.status !== ApplicationStatus.Accepted &&
      dto.status !== ApplicationStatus.Rejected
    ) {
      throw new BadRequestException(INVALID_STATUS_TRANSITION);
    }

    await this.applicationsRepository.updateApplicationStatus({
      jobId,
      applicationId,
      newStatus: dto.status,
      jobTitle: job.title,
      actorUserId: user.userId,
    });

    const detail = await this.applicationsRepository.findCompanyApplicantDetail(
      jobId,
      applicationId,
    );
    if (!detail) {
      throw new NotFoundException(APPLICATION_NOT_FOUND);
    }

    return this.toApplicantDetailDto(detail);
  }

  async setExamLink(
    user: AuthUser,
    jobId: string,
    applicationId: string,
    dto: SetExamLinkDto,
  ): Promise<ApplicantDetailDto> {
    const job = await this.requireOwnedJob(user, jobId);
    await this.applicationsRepository.setExamLink({
      jobId,
      applicationId,
      url: assertPublicHttpUrl(dto.url),
      deadline: assertFutureInstant(new Date(dto.deadline)),
      jobTitle: job.title,
    });
    return this.reloadApplicantDetail(jobId, applicationId);
  }

  async passExam(
    user: AuthUser,
    jobId: string,
    applicationId: string,
  ): Promise<ApplicantDetailDto> {
    const job = await this.requireOwnedJob(user, jobId);
    await this.applicationsRepository.passExam({
      jobId,
      applicationId,
      jobTitle: job.title,
    });
    return this.reloadApplicantDetail(jobId, applicationId);
  }

  async setInterviewLink(
    user: AuthUser,
    jobId: string,
    applicationId: string,
    dto: SetInterviewLinkDto,
  ): Promise<ApplicantDetailDto> {
    const job = await this.requireOwnedJob(user, jobId);
    await this.applicationsRepository.setInterviewLink({
      jobId,
      applicationId,
      url: interviewUrlForMode(job.interviewMode, dto.url),
      startsAt: assertFutureInstant(new Date(dto.startsAt)),
      jobTitle: job.title,
    });
    return this.reloadApplicantDetail(jobId, applicationId);
  }

  async completeExam(
    user: AuthUser,
    applicationId: string,
  ): Promise<ApplicationDetailDto> {
    this.assertStudent(user);
    const profile =
      await this.applicationsRepository.findStudentProfileByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    await this.applicationsRepository.completeExam({
      applicationId,
      studentId: profile.id,
    });
    return this.getDetail(user, applicationId);
  }

  private async requireOwnedJob(user: AuthUser, jobId: string) {
    this.assertCompany(user);
    const companyProfile =
      await this.applicationsRepository.findCompanyProfileByUserId(user.userId);
    if (!companyProfile) {
      throw new NotFoundException(COMPANY_PROFILE_NOT_FOUND);
    }
    const job = await this.applicationsRepository.findJobById(jobId);
    if (!job) {
      throw new NotFoundException(JOB_NOT_FOUND);
    }
    if (job.companyId !== companyProfile.id) {
      throw new ForbiddenException(NOT_YOUR_JOB);
    }
    return job;
  }

  private async reloadApplicantDetail(jobId: string, applicationId: string) {
    const detail = await this.applicationsRepository.findCompanyApplicantDetail(
      jobId,
      applicationId,
    );
    if (!detail) {
      throw new NotFoundException(APPLICATION_NOT_FOUND);
    }
    return this.toApplicantDetailDto(detail);
  }

  private toApplicantDetailDto(
    detail: CompanyApplicantDetailRecord,
  ): ApplicantDetailDto {
    return {
      applicationId: detail.applicationId,
      jobId: detail.jobId,
      fullName: detail.fullName,
      university: detail.university,
      major: detail.major,
      skills: detail.skills,
      bio: detail.bio ?? '',
      contactLinks: (detail.contactLinks ?? []).map((c) => ({
        id: c.id,
        platform: c.platform,
        label: c.label,
        value: c.value,
      })),
      portfolioLinks: (detail.portfolioLinks ?? []).map((p) => ({
        id: p.id,
        title: p.title,
        url: p.url,
        description: p.description,
      })),
      portfolioUrl: detail.portfolioUrl,
      resumeObjectKey: detail.resumeObjectKey,
      resumeFileName: detail.resumeFileName,
      avatarObjectKey: detail.avatarObjectKey,
      status: detail.status,
      ...selectionResponse(detail),
      coverLetter: detail.coverLetter,
      createdAt: detail.createdAt.toISOString(),
      updatedAt: detail.updatedAt.toISOString(),
      documents: detail.documents,
      interviewMode: detail.interviewMode ?? InterviewMode.Online,
    };
  }

  private assertStudent(user: AuthUser): void {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
  }

  private assertCompany(user: AuthUser): void {
    if (user.role !== UserRole.Company) {
      throw new ForbiddenException(COMPANY_ONLY);
    }
  }

  private toResponseDto(application: Application): ApplicationResponseDto {
    const dto = new ApplicationResponseDto();
    dto.id = application.id;
    dto.jobId = application.jobId;
    dto.studentId = application.studentId;
    dto.coverLetter = application.coverLetter;
    dto.resumeObjectKey = application.resumeObjectKey;
    dto.status = application.status;
    dto.createdAt = application.createdAt.toISOString();
    dto.updatedAt = application.updatedAt.toISOString();
    return dto;
  }
}

function selectionResponse(source: {
  examUrl: string | null;
  examDeadline: Date | null;
  examCompletedAt: Date | null;
  examPassedAt: Date | null;
  interviewUrl: string | null;
  interviewStartsAt: Date | null;
}) {
  return {
    examUrl: source.examUrl ?? null,
    examDeadline: source.examDeadline?.toISOString() ?? null,
    examCompletedAt: source.examCompletedAt?.toISOString() ?? null,
    examPassedAt: source.examPassedAt?.toISOString() ?? null,
    interviewUrl: source.interviewUrl ?? null,
    interviewStartsAt: source.interviewStartsAt?.toISOString() ?? null,
  };
}
