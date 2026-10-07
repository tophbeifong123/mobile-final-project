import { ForbiddenException } from '@nestjs/common';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { StorageService } from '../storage/storage.service.js';
import { InterviewMode } from '../jobs/job-enums.js';
import {
  COMPANY_ONLY,
  INTERVIEW_ONSITE_HAS_NO_LINK,
  SELECTION_LINK_INVALID,
  STUDENT_ONLY,
} from './applications.constants.js';
import { ApplicationsRepository } from './applications.repository.js';
import { ApplicationsService } from './applications.service.js';

describe('ApplicationsService selection links', () => {
  const student: AuthUser = {
    userId: 'student-user',
    email: 'student@example.com',
    role: UserRole.Student,
  };
  const company: AuthUser = {
    userId: 'company-user',
    email: 'company@example.com',
    role: UserRole.Company,
  };
  let repository: {
    findCompanyProfileByUserId: ReturnType<typeof vi.fn>;
    findJobById: ReturnType<typeof vi.fn>;
    findStudentProfileByUserId: ReturnType<typeof vi.fn>;
    setExamLink: ReturnType<typeof vi.fn>;
    setInterviewLink: ReturnType<typeof vi.fn>;
    completeExam: ReturnType<typeof vi.fn>;
    findApplicationDetail: ReturnType<typeof vi.fn>;
    findCompanyApplicantDetail: ReturnType<typeof vi.fn>;
  };
  let service: ApplicationsService;

  beforeEach(() => {
    repository = {
      findCompanyProfileByUserId: vi.fn().mockResolvedValue({ id: 'company-1' }),
      findJobById: vi.fn().mockResolvedValue({
        id: 'job-1',
        companyId: 'company-1',
        title: 'ฝึกงาน',
        interviewMode: InterviewMode.Online,
      }),
      findStudentProfileByUserId: vi.fn().mockResolvedValue({ id: 'student-1' }),
      setExamLink: vi.fn(),
      setInterviewLink: vi.fn(),
      completeExam: vi.fn(),
      findApplicationDetail: vi.fn().mockResolvedValue(detail()),
      findCompanyApplicantDetail: vi.fn().mockResolvedValue(companyDetail()),
    };
    service = new ApplicationsService(
      repository as unknown as ApplicationsRepository,
      { get: vi.fn() } as unknown as StorageService,
    );
  });

  it('rejects a student who tries to send an exam link', async () => {
    await expect(
      service.setExamLink(student, 'job-1', 'app-1', {
        url: 'https://exam.example/quiz',
        deadline: future(),
      }),
    ).rejects.toThrow(new ForbiddenException(COMPANY_ONLY));
    expect(repository.setExamLink).not.toHaveBeenCalled();
  });

  it('rejects a credentialled exam url before writing', async () => {
    await expect(
      service.setExamLink(company, 'job-1', 'app-1', {
        url: 'https://user:secret@exam.example/quiz',
        deadline: future(),
      }),
    ).rejects.toThrow(SELECTION_LINK_INVALID);
    expect(repository.setExamLink).not.toHaveBeenCalled();
  });

  it('stores a valid exam link for the owning company', async () => {
    await service.setExamLink(company, 'job-1', 'app-1', {
      url: ' https://exam.example/quiz ',
      deadline: future(),
    });
    expect(repository.setExamLink).toHaveBeenCalledWith(
      expect.objectContaining({
        url: 'https://exam.example/quiz',
        jobTitle: 'ฝึกงาน',
      }),
    );
  });

  it('rejects a company marking the exam complete', async () => {
    await expect(service.completeExam(company, 'app-1')).rejects.toThrow(
      new ForbiddenException(STUDENT_ONLY),
    );
    expect(repository.completeExam).not.toHaveBeenCalled();
  });

  it('stores an online interview link only after the exam is finished', async () => {
    await service.setInterviewLink(company, 'job-1', 'app-1', {
      url: ' https://meet.example/room ',
      startsAt: future(),
    });
    expect(repository.setInterviewLink).toHaveBeenCalledWith(
      expect.objectContaining({
        url: 'https://meet.example/room',
        jobTitle: 'ฝึกงาน',
      }),
    );
  });

  it('stores an on-site interview as a time without a link', async () => {
    repository.findJobById.mockResolvedValue({
      id: 'job-1',
      companyId: 'company-1',
      title: 'ฝึกงาน',
      interviewMode: InterviewMode.OnSite,
    });
    await service.setInterviewLink(company, 'job-1', 'app-1', {
      startsAt: future(),
    });
    expect(repository.setInterviewLink).toHaveBeenCalledWith(
      expect.objectContaining({ url: null }),
    );
    await expect(
      service.setInterviewLink(company, 'job-1', 'app-1', {
        url: 'https://meet.example/room',
        startsAt: future(),
      }),
    ).rejects.toThrow(INTERVIEW_ONSITE_HAS_NO_LINK);
  });

  it('marks the signed-in student exam complete', async () => {
    await service.completeExam(student, 'app-1');
    expect(repository.completeExam).toHaveBeenCalledWith({
      applicationId: 'app-1',
      studentId: 'student-1',
    });
  });
});

function future(): string {
  return new Date(Date.now() + 60 * 60 * 1000).toISOString();
}

function detail() {
  return {
    id: 'app-1',
    jobId: 'job-1',
    status: 'reviewing',
    coverLetter: 'สวัสดี',
    resumeObjectKey: 'cv.pdf',
    examUrl: 'https://exam.example/quiz',
    examDeadline: new Date(future()),
    examCompletedAt: new Date(),
    examPassedAt: null,
    interviewUrl: null,
    interviewStartsAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    job: {
      id: 'job-1',
      title: 'ฝึกงาน',
      companyName: 'Acme',
      province: 'สงขลา',
      workMode: 'hybrid',
      category: 'mobile',
      hasAllowance: false,
    },
    timeline: [],
  };
}

function companyDetail() {
  return {
    ...detail(),
    applicationId: 'app-1',
    studentId: 'student-1',
    fullName: 'อลิซ',
    university: 'มหาวิทยาลัยทดสอบ',
    major: 'คอมพิวเตอร์',
    skills: [],
    bio: '',
    contactLinks: [],
    portfolioLinks: [],
    portfolioUrl: null,
    resumeFileName: 'cv.pdf',
    avatarObjectKey: null,
    documents: [],
  };
}
