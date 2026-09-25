import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('student_profiles')
export class StudentProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', unique: true })
  userId: string;

  @Column({ name: 'full_name', type: 'varchar', length: 255, default: '' })
  fullName: string;

  @Column({ type: 'varchar', length: 255, default: '' })
  university: string;

  @Column({ type: 'varchar', length: 255, default: '' })
  major: string;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  skills: string[];

  @Column({ type: 'text', default: '' })
  bio: string;

  @Column({
    name: 'contact_links',
    type: 'jsonb',
    default: () => "'[]'::jsonb",
  })
  contactLinks: Array<{
    id?: string;
    platform: string;
    label?: string;
    value: string;
  }>;

  @Column({
    name: 'portfolio_links',
    type: 'jsonb',
    default: () => "'[]'::jsonb",
  })
  portfolioLinks: Array<{
    id?: string;
    title: string;
    url: string;
    description?: string;
  }>;

  @Column({
    name: 'portfolio_url',
    type: 'varchar',
    length: 2048,
    nullable: true,
  })
  portfolioUrl: string | null;

  @Column({
    name: 'resume_object_key',
    type: 'varchar',
    length: 1024,
    nullable: true,
  })
  resumeObjectKey: string | null;

  @Column({
    name: 'resume_file_name',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  resumeFileName: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
