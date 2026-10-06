import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
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

  @Index('IDX_student_profiles_university_id')
  @Column({ name: 'university_id', type: 'uuid', nullable: true })
  universityId: string | null;

  @Column({ name: 'custom_university_name', type: 'varchar', length: 255, nullable: true })
  customUniversityName: string | null;

  @Index('IDX_student_profiles_major_id')
  @Column({ name: 'major_id', type: 'uuid', nullable: true })
  majorId: string | null;

  @Column({ name: 'custom_major_name', type: 'varchar', length: 255, nullable: true })
  customMajorName: string | null;

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
    name: 'avatar_object_key',
    type: 'varchar',
    length: 1024,
    nullable: true,
  })
  avatarObjectKey: string | null;

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
