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
  COVER_LETTER_REQUIRED,
  JOB_CLOSED,
  JOB_NOT_FOUND,
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
});
