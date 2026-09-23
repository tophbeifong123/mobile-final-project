import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { Notification } from './entities/notification.entity.js';

@Injectable()
export class NotificationsRepository {
  constructor(private readonly dataSource: DataSource) {}

  async findStudentProfileByUserId(
    userId: string,
  ): Promise<StudentProfile | null> {
    return this.dataSource.getRepository(StudentProfile).findOne({
      where: { userId },
    });
  }

  async listByStudent(studentId: string): Promise<Notification[]> {
    return this.dataSource.getRepository(Notification).find({
      where: { studentId },
      order: { createdAt: 'DESC' },
    });
  }

  async markAsRead(
    id: string,
    studentId: string,
  ): Promise<Notification | null> {
    const repo = this.dataSource.getRepository(Notification);
    const notification = await repo.findOne({
      where: { id, studentId },
    });
    if (!notification) {
      return null;
    }

    if (!notification.readAt) {
      notification.readAt = new Date();
      return repo.save(notification);
    }

    return notification;
  }

  async createNotification(params: {
    studentId: string;
    applicationId: string;
    message: string;
  }): Promise<Notification> {
    const repo = this.dataSource.getRepository(Notification);
    const entity = repo.create({
      studentId: params.studentId,
      applicationId: params.applicationId,
      message: params.message,
      readAt: null,
    });
    return repo.save(entity);
  }
}
