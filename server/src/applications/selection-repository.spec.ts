import { NotFoundException } from '@nestjs/common';
import { ApplicationStatus } from './application-status.js';
import { ApplicationsRepository } from './applications.repository.js';
import { Application } from './entities/application.entity.js';

describe('ApplicationsRepository selection links', () => {
  it('saves an exam link and notifies the student', async () => {
    const application = {
      id: 'app-1',
      jobId: 'job-1',
      studentId: 'student-1',
      status: ApplicationStatus.Reviewing,
      examUrl: null,
      examDeadline: null,
      examCompletedAt: null,
      examPassedAt: null,
    } as Application;
    const saved: unknown[] = [];
    const repository = repositoryWith(application, saved);

    const deadline = new Date(Date.now() + 60 * 60 * 1000);
    await repository.setExamLink({
      jobId: 'job-1',
      applicationId: 'app-1',
      url: 'https://exam.example/quiz',
      deadline,
      jobTitle: 'ฝึกงาน Flutter',
    });

    expect(application.examUrl).toBe('https://exam.example/quiz');
    expect(application.examDeadline).toEqual(deadline);
    expect(saved).toContainEqual(
      expect.objectContaining({
        message: 'บริษัทส่งลิงก์ข้อสอบสำหรับงาน ฝึกงาน Flutter',
        studentId: 'student-1',
      }),
    );
  });

  it('marks the exam passed and notifies the student', async () => {
    const application = {
      id: 'app-1',
      jobId: 'job-1',
      studentId: 'student-1',
      status: ApplicationStatus.Reviewing,
      examUrl: 'https://exam.example/quiz',
      examDeadline: new Date(),
      examCompletedAt: new Date(),
      examPassedAt: null,
    } as Application;
    const saved: unknown[] = [];
    const repository = repositoryWith(application, saved);

    await repository.passExam({
      jobId: 'job-1',
      applicationId: 'app-1',
      jobTitle: 'ฝึกงาน Flutter',
    });

    expect(application.examPassedAt).toBeInstanceOf(Date);
    expect(saved).toContainEqual(
      expect.objectContaining({
        message: 'บริษัทตรวจว่าข้อสอบผ่านแล้วสำหรับงาน ฝึกงาน Flutter',
      }),
    );
  });

  it('hides another student exam from complete', async () => {
    const repository = repositoryWith(null, []);
    await expect(
      repository.completeExam({
        applicationId: 'app-1',
        studentId: 'someone-else',
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});

function repositoryWith(application: Application | null, saved: unknown[]) {
  const manager = {
    createQueryBuilder: () => ({
      setLock: () => ({
        where: () => ({
          getOne: async () => application,
        }),
      }),
    }),
    create: (_entity: unknown, value: unknown) => value,
    save: async (_entity: unknown, value: unknown) => {
      saved.push(value);
      return value;
    },
  };
  return new ApplicationsRepository({
    transaction: async (callback: (current: typeof manager) => Promise<void>) =>
      callback(manager),
  } as never);
}
