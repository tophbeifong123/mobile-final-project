import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
  VersionColumn,
} from 'typeorm';
import { ApplicationStatus } from '../application-status.js';

@Entity('applications')
export class Application {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'student_id', type: 'uuid' })
  studentId: string;

  @Column({ name: 'job_id', type: 'uuid' })
  jobId: string;

  @Column({ name: 'cover_letter', type: 'text' })
  coverLetter: string;

  @Column({ name: 'resume_object_key', type: 'varchar', length: 1024 })
  resumeObjectKey: string;

  @Column({ name: 'resume_file_name', type: 'varchar', length: 255, nullable: true })
  resumeFileName: string | null;

  @Column({
    type: 'enum',
    enum: ApplicationStatus,
    enumName: 'application_status',
    default: ApplicationStatus.Submitted,
  })
  status: ApplicationStatus;

  @Column({ name: 'exam_url', type: 'varchar', length: 2048, nullable: true })
  examUrl: string | null;

  @Column({ name: 'exam_deadline', type: 'timestamptz', nullable: true })
  examDeadline: Date | null;

  @Column({ name: 'exam_completed_at', type: 'timestamptz', nullable: true })
  examCompletedAt: Date | null;

  @Column({ name: 'exam_passed_at', type: 'timestamptz', nullable: true })
  examPassedAt: Date | null;

  @Column({ name: 'interview_url', type: 'varchar', length: 2048, nullable: true })
  interviewUrl: string | null;

  @Column({ name: 'interview_starts_at', type: 'timestamptz', nullable: true })
  interviewStartsAt: Date | null;

  @VersionColumn()
  version: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
