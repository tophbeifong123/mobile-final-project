import { beforeEach, describe, expect, it, vi } from 'vitest';
import {
  ForbiddenException,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ApplicationsService } from './applications.service.js';
import {
  ApplicationsRepository,
  type CompanyApplicantDetailRecord,
} from './applications.repository.js';
import { StorageService } from '../storage/storage.service.js';
import { UserRole } from '../auth/user-role.js';
import { type AuthUser } from '../auth/auth-user.js';
import { ApplicationStatus } from './application-status.js';

describe('company application resume snapshot', () => {
  const user: AuthUser = {
    userId: 'company-user',
    email: 'company@example.com',
    role: UserRole.Company,
  };
  const pdf = Buffer.from('%PDF-1.4 application snapshot');
  const record: CompanyApplicantDetailRecord = {
    applicationId: 'application',
    jobId: 'job',
    studentId: 'student',
    fullName: 'Student',
    university: 'PSU',
    major: 'IT',
    skills: [],
    bio: '',
    contactLinks: [],
    portfolioLinks: [],
    portfolioUrl: null,
    avatarObjectKey: null,
    resumeFileName: 'original.pdf',
    resumeObjectKey: 'resumes/student/original.pdf',
    status: ApplicationStatus.Submitted,
    coverLetter: 'Hello',
    createdAt: new Date(),
    updatedAt: new Date(),
  };
  const repository = {
    findCompanyProfileByUserId: vi.fn(),
    findJobById: vi.fn(),
    findCompanyApplicantDetail: vi.fn(),
  };
  const storage = { get: vi.fn() };
  const service = new ApplicationsService(
    repository as unknown as ApplicationsRepository,
    storage as unknown as StorageService,
  );

  beforeEach(() => {
    vi.resetAllMocks();
    repository.findCompanyProfileByUserId.mockResolvedValue({ id: 'company' });
    repository.findJobById.mockResolvedValue({
      id: 'job',
      companyId: 'company',
    });
    repository.findCompanyApplicantDetail.mockResolvedValue(record);
    storage.get.mockResolvedValue(pdf);
  });

  it('reads only the application key, not the current student resume', async () => {
    expect(
      await service.getApplicantResume(user, 'job', 'application'),
    ).toEqual(pdf);
    expect(repository.findCompanyApplicantDetail).toHaveBeenCalledWith(
      'job',
      'application',
    );
    expect(storage.get).toHaveBeenCalledExactlyOnceWith(record.resumeObjectKey);
  });
  it('rejects students before querying storage or ownership', async () => {
    await expect(
      service.getApplicantResume(
        { ...user, role: UserRole.Student },
        'job',
        'application',
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(repository.findCompanyProfileByUserId).not.toHaveBeenCalled();
    expect(storage.get).not.toHaveBeenCalled();
  });
  it('rejects another company before reading the application or storage', async () => {
    repository.findJobById.mockResolvedValue({ companyId: 'other-company' });
    await expect(
      service.getApplicantResume(user, 'job', 'application'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(repository.findCompanyApplicantDetail).not.toHaveBeenCalled();
    expect(storage.get).not.toHaveBeenCalled();
  });
  for (const method of [
    'findCompanyProfileByUserId',
    'findJobById',
    'findCompanyApplicantDetail',
  ] as const) {
    it('returns 404 when ' + method + ' is missing', async () => {
      repository[method].mockResolvedValue(null);
      await expect(
        service.getApplicantResume(user, 'job', 'wrong-application'),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(storage.get).not.toHaveBeenCalled();
    });
  }
  it('rejects a missing snapshot key without reading storage', async () => {
    repository.findCompanyApplicantDetail.mockResolvedValue({
      ...record,
      resumeObjectKey: '',
    });
    await expect(
      service.getApplicantResume(user, 'job', 'application'),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(storage.get).not.toHaveBeenCalled();
  });
  for (const value of [null, Buffer.alloc(0), Buffer.from('HTML-not-pdf')]) {
    it(
      'rejects missing or non-PDF storage content: ' + String(value),
      async () => {
        storage.get.mockResolvedValue(value);
        await expect(
          service.getApplicantResume(user, 'job', 'application'),
        ).rejects.toBeInstanceOf(NotFoundException);
      },
    );
  }
  it('maps storage failures to a safe retryable message', async () => {
    storage.get.mockRejectedValue(new Error('private storage credentials'));
    await expect(
      service.getApplicantResume(user, 'job', 'application'),
    ).rejects.toThrow(
      new ServiceUnavailableException('เปิดไฟล์ Resume ไม่สำเร็จ กรุณาลองใหม่'),
    );
  });
});
