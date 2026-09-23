import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { NotificationItemDto } from './dto/notification-item.dto.js';
import {
  NOTIFICATION_NOT_FOUND,
  PROFILE_NOT_FOUND,
  STUDENT_ONLY,
} from './notifications.constants.js';
import { NotificationsRepository } from './notifications.repository.js';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly notificationsRepository: NotificationsRepository,
  ) {}

  async list(user: AuthUser): Promise<NotificationItemDto[]> {
    this.assertStudent(user);

    const profile =
      await this.notificationsRepository.findStudentProfileByUserId(
        user.userId,
      );
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    const items = await this.notificationsRepository.listByStudent(profile.id);

    return items.map((item) => ({
      id: item.id,
      applicationId: item.applicationId,
      message: item.message,
      readAt: item.readAt ? item.readAt.toISOString() : null,
      createdAt: item.createdAt.toISOString(),
    }));
  }

  async markAsRead(user: AuthUser, id: string): Promise<NotificationItemDto> {
    this.assertStudent(user);

    const profile =
      await this.notificationsRepository.findStudentProfileByUserId(
        user.userId,
      );
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    const updated = await this.notificationsRepository.markAsRead(
      id,
      profile.id,
    );
    if (!updated) {
      throw new NotFoundException(NOTIFICATION_NOT_FOUND);
    }

    return {
      id: updated.id,
      applicationId: updated.applicationId,
      message: updated.message,
      readAt: updated.readAt ? updated.readAt.toISOString() : null,
      createdAt: updated.createdAt.toISOString(),
    };
  }

  private assertStudent(user: AuthUser): void {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
  }
}
