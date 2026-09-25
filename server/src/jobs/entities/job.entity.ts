import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
  VersionColumn,
} from 'typeorm';
import { JobStatus, WorkMode } from '../job-enums.js';

@Entity('jobs')
export class Job {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'company_id', type: 'uuid' })
  companyId: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ type: 'varchar', length: 255 })
  province: string;

  @Column({
    name: 'work_mode',
    type: 'enum',
    enum: WorkMode,
    enumName: 'work_mode',
  })
  workMode: WorkMode;

  @Column({ type: 'varchar', length: 255 })
  category: string;

  @Column({ name: 'has_allowance', type: 'boolean' })
  hasAllowance: boolean;

  @Column({ type: 'text' })
  requirements: string;

  @Column('text', { array: true, default: () => "ARRAY[]::text[]" })
  skills: string[];

  @Column({
    type: 'enum',
    enum: JobStatus,
    enumName: 'job_status',
    default: JobStatus.Open,
  })
  status: JobStatus;

  @VersionColumn()
  version: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
