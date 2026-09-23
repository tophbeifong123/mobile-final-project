import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { ApplicationStatus } from '../application-status.js';

@Entity('application_status_events')
export class ApplicationStatusEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'application_id', type: 'uuid' })
  applicationId: string;

  @Column({
    name: 'from_status',
    type: 'enum',
    enum: ApplicationStatus,
    enumName: 'application_status',
    nullable: true,
  })
  fromStatus: ApplicationStatus | null;

  @Column({
    name: 'to_status',
    type: 'enum',
    enum: ApplicationStatus,
    enumName: 'application_status',
  })
  toStatus: ApplicationStatus;

  @Column({ name: 'actor_user_id', type: 'uuid' })
  actorUserId: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
