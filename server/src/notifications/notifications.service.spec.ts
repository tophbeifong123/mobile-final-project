import {
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import {
  NOTIFICATION_NOT_FOUND,
  PROFILE_NOT_FOUND,
  STUDENT_ONLY,
} from './notifications.constants.js';
import { NotificationsRepository } from './notifications.repository.js';
import { NotificationsService } from './notifications.service.js';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let repository: NotificationsRepository;

  const studentUser: AuthUser = {
    userId: 'student-user-1',
    email: 'student@example.com',
    role: UserRole.Student,
  };

  const companyUser: AuthUser = {
    userId: 'company-user-1',
    email: 'company@example.com',
    role: UserRole.Company,
  };

  const studentProfile = {
    id: 'student-profile-1',
    userId: 'student-user-1',
  };

  beforeEach(() => {
    repository = {
      findStudentProfileByUserId: vi.fn(),
      listByStudent: vi.fn(),
      markAsRead: vi.fn(),
      createNotification: vi.fn(),
    } as unknown as NotificationsRepository;

    service = new NotificationsService(repository);
  });

  describe('list', () => {
    it('rejects if user is not student', async () => {
      await expect(service.list(companyUser)).rejects.toThrow(
        new ForbiddenException(STUDENT_ONLY),
      );
    });

    it('rejects if student profile does not exist', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(null);

      await expect(service.list(studentUser)).rejects.toThrow(
        new NotFoundException(PROFILE_NOT_FOUND),
      );
    });

    it('returns student notifications mapped to DTO', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
        studentProfile as any,
      );
      vi.mocked(repository.listByStudent).mockResolvedValue([
        {
          id: 'notif-1',
          studentId: 'student-profile-1',
          applicationId: 'app-1',
          message: 'สถานะใบสมัครเปลี่ยนเป็น reviewing',
          readAt: null,
          createdAt: new Date('2026-09-23T12:00:00Z'),
        } as any,
      ]);

      const result = await service.list(studentUser);

      expect(repository.listByStudent).toHaveBeenCalledWith('student-profile-1');
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('notif-1');
      expect(result[0].applicationId).toBe('app-1');
      expect(result[0].message).toBe('สถานะใบสมัครเปลี่ยนเป็น reviewing');
      expect(result[0].readAt).toBeNull();
      expect(result[0].createdAt).toBe('2026-09-23T12:00:00.000Z');
    });
  });

  describe('markAsRead', () => {
    it('rejects if user is not student', async () => {
      await expect(service.markAsRead(companyUser, 'notif-1')).rejects.toThrow(
        new ForbiddenException(STUDENT_ONLY),
      );
    });

    it('rejects if student profile does not exist', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(null);

      await expect(service.markAsRead(studentUser, 'notif-1')).rejects.toThrow(
        new NotFoundException(PROFILE_NOT_FOUND),
      );
    });

    it('rejects if notification not found', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
        studentProfile as any,
      );
      vi.mocked(repository.markAsRead).mockResolvedValue(null);

      await expect(service.markAsRead(studentUser, 'notif-1')).rejects.toThrow(
        new NotFoundException(NOTIFICATION_NOT_FOUND),
      );
    });

    it('returns updated notification with readAt timestamp', async () => {
      vi.mocked(repository.findStudentProfileByUserId).mockResolvedValue(
        studentProfile as any,
      );
      vi.mocked(repository.markAsRead).mockResolvedValue({
        id: 'notif-1',
        studentId: 'student-profile-1',
        applicationId: 'app-1',
        message: 'สถานะใบสมัครเปลี่ยนเป็น reviewing',
        readAt: new Date('2026-09-23T12:30:00Z'),
        createdAt: new Date('2026-09-23T12:00:00Z'),
      } as any);

      const result = await service.markAsRead(studentUser, 'notif-1');

      expect(repository.markAsRead).toHaveBeenCalledWith(
        'notif-1',
        'student-profile-1',
      );
      expect(result.id).toBe('notif-1');
      expect(result.readAt).toBe('2026-09-23T12:30:00.000Z');
    });
  });
});
