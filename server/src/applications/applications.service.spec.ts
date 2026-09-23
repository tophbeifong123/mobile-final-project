import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { ApplicationStatus } from './application-status.js';
import {
  ALREADY_APPLIED,
  APPLICATION_NOT_FOUND,
  COMPANY_ONLY,
  COMPANY_PROFILE_NOT_FOUND,
  COVER_LETTER_REQUIRED,
  INVALID_STATUS_TRANSITION,
  JOB_CLOSED,
  JOB_NOT_FOUND,
  NOT_YOUR_JOB,
  PROFILE_NOT_FOUND,
  RESUME_REQUIRED,
  STUDENT_ONLY,
} from './applications.constants.js';
import { ApplicationsRepository } from './applications.repository.js';
import { ApplicationsService } from './applications.service.js';
import { Application } from './entities/application.entity.js';

describe('ApplicationsService', () => {
  let service: ApplicationsService;
  let repository: ApplicationsRepository;

  const studentUser: AuthUser = {
    userId: 'student-user-123',
    email: 'student@example.com',
    role: UserRole.Student,
  };

  const companyUser: AuthUser = {
    userId: 'company-user-456',
    email: 'company@example.com',
    role: UserRole.Company,
  };

  const studentProfile = {
    id: 'student-profile-123',
    userId: 'student-user-123',
    fullName: 'Jane Student',
    university: 'CU',
    major: 'CS',
    skills: ['Flutter', 'Node.js'],
    portfolioUrl: null,
    resumeObjectKey: 'resumes/student-user-123/resume.pdf',
    resumeFileName: 'resume.pdf',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(() => {
    repository = {
      findStudentProfileByUserId: vi.fn(),
      findApplication: vi.fn(),
      applyJob: vi.fn(),
    } as unknown as ApplicationsRepository;

    service = new ApplicationsService(repository);
  });

  it('rejects if user role is not student', async () => {
    await expect(
      service.apply(companyUser, 'job-1', { coverLetter: 'Hello' }),
    ).rejects.toThrow(new ForbiddenException(STUDENT_ONLY));
  });

  it('rejects if coverLetter is empty or whitespace', async () => {
    await expect(
      service.apply(studentUser, 'job-1', { coverLetter: '   ' }),
    ).rejects.toThrow(new BadRequestException(COVER_LETTER_REQUIRED));
  });

  it('rejects if student profile does not exist', async () => {
    vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(null);

    await expect(
      service.apply(studentUser, 'job-1', { coverLetter: 'Hello' }),
    ).rejects.toThrow(new NotFoundException(PROFILE_NOT_FOUND));
  });

  it('rejects if student profile has no resumeObjectKey', async () => {
    vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue({
      ...studentProfile,
      resumeObjectKey: null,
    });

    await expect(
      service.apply(studentUser, 'job-1', { coverLetter: 'Hello' }),
    ).rejects.toThrow(new BadRequestException(RESUME_REQUIRED));
  });

  it('applies successfully and returns application response with submitted status', async () => {
    vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
      studentProfile as any,
    );

    const mockApplication = new Application();
    mockApplication.id = 'app-123';
    mockApplication.studentId = studentProfile.id;
    mockApplication.jobId = 'job-1';
    mockApplication.coverLetter = 'I am passionate about this internship';
    mockApplication.resumeObjectKey = studentProfile.resumeObjectKey!;
    mockApplication.status = ApplicationStatus.Submitted;
    mockApplication.version = 1;
    mockApplication.createdAt = new Date('2026-09-23T10:00:00Z');
    mockApplication.updatedAt = new Date('2026-09-23T10:00:00Z');

    vi.mocked(repository.applyJob).mockResolvedValue(mockApplication);

    const result = await service.apply(studentUser, 'job-1', {
      coverLetter: 'I am passionate about this internship',
    });

    expect(repository.applyJob).toHaveBeenCalledWith({
      studentId: studentProfile.id,
      jobId: 'job-1',
      coverLetter: 'I am passionate about this internship',
      resumeObjectKey: studentProfile.resumeObjectKey,
      actorUserId: studentUser.userId,
    });

    expect(result.id).toBe('app-123');
    expect(result.status).toBe(ApplicationStatus.Submitted);
    expect(result.coverLetter).toBe('I am passionate about this internship');
    expect(result.resumeObjectKey).toBe(studentProfile.resumeObjectKey);
  });

  it('propagates NotFoundException when job is not found', async () => {
    vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
      studentProfile as any,
    );
    vi.mocked(repository.applyJob).mockRejectedValue(
      new NotFoundException(JOB_NOT_FOUND),
    );

    await expect(
      service.apply(studentUser, 'job-unknown', { coverLetter: 'Hello' }),
    ).rejects.toThrow(new NotFoundException(JOB_NOT_FOUND));
  });

  it('propagates BadRequestException when job is closed', async () => {
    vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
      studentProfile as any,
    );
    vi.mocked(repository.applyJob).mockRejectedValue(
      new BadRequestException(JOB_CLOSED),
    );

    await expect(
      service.apply(studentUser, 'job-closed', { coverLetter: 'Hello' }),
    ).rejects.toThrow(new BadRequestException(JOB_CLOSED));
  });

  it('propagates ConflictException when user has already applied', async () => {
    vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
      studentProfile as any,
    );
    vi.mocked(repository.applyJob).mockRejectedValue(
      new ConflictException(ALREADY_APPLIED),
    );

    await expect(
      service.apply(studentUser, 'job-1', { coverLetter: 'Hello' }),
    ).rejects.toThrow(new ConflictException(ALREADY_APPLIED));
  });

  describe('getMine', () => {
    it('rejects if user role is not student', async () => {
      await expect(service.getMine(companyUser)).rejects.toThrow(
        new ForbiddenException(STUDENT_ONLY),
      );
    });

    it('rejects if student profile does not exist', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(null);

      await expect(service.getMine(studentUser)).rejects.toThrow(
        new NotFoundException(PROFILE_NOT_FOUND),
      );
    });

    it('returns student applications list mapped to DTO', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
        studentProfile as any,
      );
      (repository as any).listStudentApplications = vi.fn().mockResolvedValue([
        {
          id: 'app-1',
          jobId: 'job-1',
          jobTitle: 'Flutter Intern',
          companyName: 'Tech Co',
          status: ApplicationStatus.Submitted,
          coverLetter: 'Hello',
          resumeObjectKey: 'resumes/key.pdf',
          createdAt: new Date('2026-09-23T10:00:00Z'),
          updatedAt: new Date('2026-09-23T10:00:00Z'),
        },
      ]);

      const result = await service.getMine(studentUser);

      expect((repository as any).listStudentApplications).toHaveBeenCalledWith(
        studentProfile.id,
      );
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('app-1');
      expect(result[0].jobTitle).toBe('Flutter Intern');
      expect(result[0].companyName).toBe('Tech Co');
      expect(result[0].status).toBe(ApplicationStatus.Submitted);
      expect(result[0].createdAt).toBe('2026-09-23T10:00:00.000Z');
    });
  });

  describe('getDetail', () => {
    it('rejects if user role is not student', async () => {
      await expect(service.getDetail(companyUser, 'app-1')).rejects.toThrow(
        new ForbiddenException(STUDENT_ONLY),
      );
    });

    it('rejects if student profile does not exist', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(null);

      await expect(service.getDetail(studentUser, 'app-1')).rejects.toThrow(
        new NotFoundException(PROFILE_NOT_FOUND),
      );
    });

    it('rejects if application is not found or does not belong to student', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
        studentProfile as any,
      );
      (repository as any).findApplicationDetail = vi.fn().mockResolvedValue(null);

      await expect(service.getDetail(studentUser, 'app-1')).rejects.toThrow(
        new NotFoundException(APPLICATION_NOT_FOUND),
      );
    });

    it('returns full application detail with job info and timeline events', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
        studentProfile as any,
      );
      (repository as any).findApplicationDetail = vi.fn().mockResolvedValue({
        id: 'app-1',
        jobId: 'job-1',
        status: ApplicationStatus.Submitted,
        coverLetter: 'My cover letter',
        resumeObjectKey: 'resumes/key.pdf',
        createdAt: new Date('2026-09-23T10:00:00Z'),
        updatedAt: new Date('2026-09-23T10:00:00Z'),
        job: {
          id: 'job-1',
          title: 'Mobile Engineer',
          companyName: 'Tech Co',
          province: 'กรุงเทพมหานคร',
          workMode: 'on_site',
          category: 'Mobile',
          hasAllowance: true,
        },
        timeline: [
          {
            id: 'event-1',
            fromStatus: null,
            toStatus: ApplicationStatus.Submitted,
            createdAt: new Date('2026-09-23T10:00:00Z'),
          },
        ],
      });

      const result = await service.getDetail(studentUser, 'app-1');

      expect((repository as any).findApplicationDetail).toHaveBeenCalledWith(
        'app-1',
        studentProfile.id,
      );
      expect(result.id).toBe('app-1');
      expect(result.job.title).toBe('Mobile Engineer');
      expect(result.job.companyName).toBe('Tech Co');
      expect(result.status).toBe(ApplicationStatus.Submitted);
      expect(result.coverLetter).toBe('My cover letter');
      expect(result.resumeObjectKey).toBe('resumes/key.pdf');
      expect(result.createdAt).toBe('2026-09-23T10:00:00.000Z');
      expect(result.timeline).toHaveLength(1);
      expect(result.timeline[0].toStatus).toBe(ApplicationStatus.Submitted);
      expect(result.timeline[0].fromStatus).toBeNull();
      expect(result.timeline[0].createdAt).toBe('2026-09-23T10:00:00.000Z');
    });
  });

  describe('getJobApplicants', () => {
    const companyProfile = {
      id: 'company-profile-456',
      userId: 'company-user-456',
      name: 'Tech Co',
    };

    const targetJob = {
      id: 'job-123',
      companyId: 'company-profile-456',
      title: 'Frontend Intern',
    };

    it('rejects if role is not company', async () => {
      await expect(
        service.getJobApplicants(studentUser, 'job-123'),
      ).rejects.toThrow(new ForbiddenException(COMPANY_ONLY));
    });

    it('throws NotFoundException if company profile does not exist', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(null);

      await expect(
        service.getJobApplicants(companyUser, 'job-123'),
      ).rejects.toThrow(new NotFoundException(COMPANY_PROFILE_NOT_FOUND));
    });

    it('throws NotFoundException if job does not exist', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue(null);

      await expect(
        service.getJobApplicants(companyUser, 'job-123'),
      ).rejects.toThrow(new NotFoundException(JOB_NOT_FOUND));
    });

    it('throws ForbiddenException if job belongs to another company', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue({
        id: 'job-123',
        companyId: 'other-company-789',
      });

      await expect(
        service.getJobApplicants(companyUser, 'job-123'),
      ).rejects.toThrow(new ForbiddenException(NOT_YOUR_JOB));
    });

    it('returns applicants for company job with full details', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi
        .fn()
        .mockResolvedValue(targetJob);
      (repository as any).listJobApplicants = vi.fn().mockResolvedValue([
        {
          applicationId: 'app-1',
          fullName: 'สมชาย ใจดี',
          university: 'มหาวิทยาลัยเกษตรศาสตร์',
          major: 'วิทยาการคอมพิวเตอร์',
          status: ApplicationStatus.Submitted,
          coverLetter: 'อยากฝึกงานที่นี่ครับ',
          createdAt: new Date('2026-09-23T12:00:00Z'),
        },
      ]);

      const result = await service.getJobApplicants(companyUser, 'job-123');

      expect((repository as any).listJobApplicants).toHaveBeenCalledWith(
        'job-123',
      );
      expect(result).toHaveLength(1);
      expect(result[0]).toEqual({
        applicationId: 'app-1',
        fullName: 'สมชาย ใจดี',
        university: 'มหาวิทยาลัยเกษตรศาสตร์',
        major: 'วิทยาการคอมพิวเตอร์',
        status: ApplicationStatus.Submitted,
        coverLetter: 'อยากฝึกงานที่นี่ครับ',
        createdAt: '2026-09-23T12:00:00.000Z',
      });
    });
  });

  describe('getApplicantDetail', () => {
    const companyProfile = {
      id: 'company-profile-456',
      userId: 'company-user-456',
      name: 'Tech Co',
    };

    const targetJob = {
      id: 'job-123',
      companyId: 'company-profile-456',
      title: 'Frontend Intern',
    };

    it('rejects if role is not company', async () => {
      await expect(
        service.getApplicantDetail(studentUser, 'job-123', 'app-1'),
      ).rejects.toThrow(new ForbiddenException(COMPANY_ONLY));
    });

    it('throws NotFoundException if company profile does not exist', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(null);

      await expect(
        service.getApplicantDetail(companyUser, 'job-123', 'app-1'),
      ).rejects.toThrow(new NotFoundException(COMPANY_PROFILE_NOT_FOUND));
    });

    it('throws NotFoundException if job does not exist', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue(null);

      await expect(
        service.getApplicantDetail(companyUser, 'job-123', 'app-1'),
      ).rejects.toThrow(new NotFoundException(JOB_NOT_FOUND));
    });

    it('throws ForbiddenException if job belongs to another company', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue({
        id: 'job-123',
        companyId: 'other-company-789',
      });

      await expect(
        service.getApplicantDetail(companyUser, 'job-123', 'app-1'),
      ).rejects.toThrow(new ForbiddenException(NOT_YOUR_JOB));
    });

    it('throws NotFoundException if applicant detail does not exist', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi
        .fn()
        .mockResolvedValue(targetJob);
      (repository as any).findCompanyApplicantDetail = vi
        .fn()
        .mockResolvedValue(null);

      await expect(
        service.getApplicantDetail(companyUser, 'job-123', 'app-non-existent'),
      ).rejects.toThrow(new NotFoundException(APPLICATION_NOT_FOUND));
    });

    it('returns full applicant detail including profile, resume, and cover letter', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi
        .fn()
        .mockResolvedValue(targetJob);
      (repository as any).findCompanyApplicantDetail = vi
        .fn()
        .mockResolvedValue({
          applicationId: 'app-1',
          jobId: 'job-123',
          studentId: 'student-profile-123',
          fullName: 'สมชาย ใจดี',
          university: 'มหาวิทยาลัยเกษตรศาสตร์',
          major: 'วิทยาการคอมพิวเตอร์',
          skills: ['Flutter', 'Dart', 'Node.js'],
          portfolioUrl: 'https://github.com/somchai',
          resumeFileName: 'somchai-resume.pdf',
          status: ApplicationStatus.Submitted,
          coverLetter: 'อยากฝึกงานที่นี่มากครับ',
          resumeObjectKey: 'resumes/somchai.pdf',
          createdAt: new Date('2026-09-23T12:00:00Z'),
          updatedAt: new Date('2026-09-23T12:30:00Z'),
        });

      const result = await service.getApplicantDetail(
        companyUser,
        'job-123',
        'app-1',
      );

      expect(
        (repository as any).findCompanyApplicantDetail,
      ).toHaveBeenCalledWith('job-123', 'app-1');
      expect(result).toEqual({
        applicationId: 'app-1',
        jobId: 'job-123',
        fullName: 'สมชาย ใจดี',
        university: 'มหาวิทยาลัยเกษตรศาสตร์',
        major: 'วิทยาการคอมพิวเตอร์',
        skills: ['Flutter', 'Dart', 'Node.js'],
        portfolioUrl: 'https://github.com/somchai',
        resumeFileName: 'somchai-resume.pdf',
        resumeObjectKey: 'resumes/somchai.pdf',
        status: ApplicationStatus.Submitted,
        coverLetter: 'อยากฝึกงานที่นี่มากครับ',
        createdAt: '2026-09-23T12:00:00.000Z',
        updatedAt: '2026-09-23T12:30:00.000Z',
      });
    });
  });

  describe('updateApplicantStatus', () => {
    const companyProfile = {
      id: 'company-profile-456',
      userId: 'company-user-456',
      name: 'Tech Co',
    };

    const targetJob = {
      id: 'job-123',
      companyId: 'company-profile-456',
      title: 'Frontend Intern',
    };

    it('rejects if role is not company', async () => {
      await expect(
        service.updateApplicantStatus(studentUser, 'job-123', 'app-1', {
          status: ApplicationStatus.Reviewing,
        }),
      ).rejects.toThrow(new ForbiddenException(COMPANY_ONLY));
    });

    it('throws NotFoundException if company profile does not exist', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(null);

      await expect(
        service.updateApplicantStatus(companyUser, 'job-123', 'app-1', {
          status: ApplicationStatus.Reviewing,
        }),
      ).rejects.toThrow(new NotFoundException(COMPANY_PROFILE_NOT_FOUND));
    });

    it('throws NotFoundException if job does not exist', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue(null);

      await expect(
        service.updateApplicantStatus(companyUser, 'job-123', 'app-1', {
          status: ApplicationStatus.Reviewing,
        }),
      ).rejects.toThrow(new NotFoundException(JOB_NOT_FOUND));
    });

    it('throws ForbiddenException if job belongs to another company', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue({
        id: 'job-123',
        companyId: 'other-company-789',
      });

      await expect(
        service.updateApplicantStatus(companyUser, 'job-123', 'app-1', {
          status: ApplicationStatus.Reviewing,
        }),
      ).rejects.toThrow(new ForbiddenException(NOT_YOUR_JOB));
    });

    it('throws BadRequestException if requested status is not Reviewing, Accepted, or Rejected', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue(targetJob);

      await expect(
        service.updateApplicantStatus(companyUser, 'job-123', 'app-1', {
          status: ApplicationStatus.Submitted,
        }),
      ).rejects.toThrow(new BadRequestException(INVALID_STATUS_TRANSITION));
    });

    it('updates status to reviewing and returns updated applicant detail', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue(targetJob);
      (repository as any).updateApplicationStatus = vi
        .fn()
        .mockResolvedValue({ id: 'app-1', status: ApplicationStatus.Reviewing });
      (repository as any).findCompanyApplicantDetail = vi.fn().mockResolvedValue({
        applicationId: 'app-1',
        jobId: 'job-123',
        studentId: 'student-profile-123',
        fullName: 'สมชาย ใจดี',
        university: 'มหาวิทยาลัยเกษตรศาสตร์',
        major: 'วิทยาการคอมพิวเตอร์',
        skills: ['Flutter'],
        portfolioUrl: null,
        resumeFileName: 'resume.pdf',
        status: ApplicationStatus.Reviewing,
        coverLetter: 'อยากฝึกงานที่นี่มากครับ',
        resumeObjectKey: 'resumes/somchai.pdf',
        createdAt: new Date('2026-09-23T12:00:00Z'),
        updatedAt: new Date('2026-09-23T12:45:00Z'),
      });

      const result = await service.updateApplicantStatus(
        companyUser,
        'job-123',
        'app-1',
        { status: ApplicationStatus.Reviewing },
      );

      expect(
        (repository as any).updateApplicationStatus,
      ).toHaveBeenCalledWith({
        jobId: 'job-123',
        applicationId: 'app-1',
        newStatus: ApplicationStatus.Reviewing,
        jobTitle: targetJob.title,
        actorUserId: companyUser.userId,
      });

      expect(result.status).toBe(ApplicationStatus.Reviewing);
      expect(result.applicationId).toBe('app-1');
      expect(result.fullName).toBe('สมชาย ใจดี');
    });

    it('updates status to accepted and returns updated applicant detail', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue(targetJob);
      (repository as any).updateApplicationStatus = vi
        .fn()
        .mockResolvedValue({ id: 'app-1', status: ApplicationStatus.Accepted });
      (repository as any).findCompanyApplicantDetail = vi.fn().mockResolvedValue({
        applicationId: 'app-1',
        jobId: 'job-123',
        studentId: 'student-profile-123',
        fullName: 'สมชาย ใจดี',
        university: 'มหาวิทยาลัยเกษตรศาสตร์',
        major: 'วิทยาการคอมพิวเตอร์',
        skills: ['Flutter'],
        portfolioUrl: null,
        resumeFileName: 'resume.pdf',
        status: ApplicationStatus.Accepted,
        coverLetter: 'อยากฝึกงานที่นี่มากครับ',
        resumeObjectKey: 'resumes/somchai.pdf',
        createdAt: new Date('2026-09-23T12:00:00Z'),
        updatedAt: new Date('2026-09-23T13:00:00Z'),
      });

      const result = await service.updateApplicantStatus(
        companyUser,
        'job-123',
        'app-1',
        { status: ApplicationStatus.Accepted },
      );

      expect(
        (repository as any).updateApplicationStatus,
      ).toHaveBeenCalledWith({
        jobId: 'job-123',
        applicationId: 'app-1',
        newStatus: ApplicationStatus.Accepted,
        jobTitle: targetJob.title,
        actorUserId: companyUser.userId,
      });

      expect(result.status).toBe(ApplicationStatus.Accepted);
      expect(result.applicationId).toBe('app-1');
    });

    it('updates status to rejected and returns updated applicant detail', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue(targetJob);
      (repository as any).updateApplicationStatus = vi
        .fn()
        .mockResolvedValue({ id: 'app-1', status: ApplicationStatus.Rejected });
      (repository as any).findCompanyApplicantDetail = vi.fn().mockResolvedValue({
        applicationId: 'app-1',
        jobId: 'job-123',
        studentId: 'student-profile-123',
        fullName: 'สมชาย ใจดี',
        university: 'มหาวิทยาลัยเกษตรศาสตร์',
        major: 'วิทยาการคอมพิวเตอร์',
        skills: ['Flutter'],
        portfolioUrl: null,
        resumeFileName: 'resume.pdf',
        status: ApplicationStatus.Rejected,
        coverLetter: 'อยากฝึกงานที่นี่มากครับ',
        resumeObjectKey: 'resumes/somchai.pdf',
        createdAt: new Date('2026-09-23T12:00:00Z'),
        updatedAt: new Date('2026-09-23T13:00:00Z'),
      });

      const result = await service.updateApplicantStatus(
        companyUser,
        'job-123',
        'app-1',
        { status: ApplicationStatus.Rejected },
      );

      expect(
        (repository as any).updateApplicationStatus,
      ).toHaveBeenCalledWith({
        jobId: 'job-123',
        applicationId: 'app-1',
        newStatus: ApplicationStatus.Rejected,
        jobTitle: targetJob.title,
        actorUserId: companyUser.userId,
      });

      expect(result.status).toBe(ApplicationStatus.Rejected);
      expect(result.applicationId).toBe('app-1');
    });

    it('throws NotFoundException if applicant detail cannot be found after update', async () => {
      (repository as any).findCompanyProfileByUserId = vi
        .fn()
        .mockResolvedValue(companyProfile);
      (repository as any).findJobById = vi.fn().mockResolvedValue(targetJob);
      (repository as any).updateApplicationStatus = vi
        .fn()
        .mockResolvedValue({ id: 'app-1', status: ApplicationStatus.Reviewing });
      (repository as any).findCompanyApplicantDetail = vi.fn().mockResolvedValue(null);

      await expect(
        service.updateApplicantStatus(companyUser, 'job-123', 'app-1', {
          status: ApplicationStatus.Reviewing,
        }),
      ).rejects.toThrow(new NotFoundException(APPLICATION_NOT_FOUND));
    });
  });
});

