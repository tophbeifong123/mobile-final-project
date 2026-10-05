import {
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  Column,
  UpdateDateColumn,
} from 'typeorm';

export enum StudentDocumentType {
  Cv = 'cv',
  Transcript = 'transcript',
  Other = 'other',
}

@Entity('student_documents')
@Index('UQ_student_documents_single_type', ['studentId', 'type'], {
  unique: true,
  where: 'type IN (\'cv\', \'transcript\')',
})
@Index('IDX_student_documents_student_id', ['studentId'])
export class StudentDocument {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'student_id', type: 'uuid' })
  studentId: string;

  @Column({ type: 'varchar', length: 16 })
  type: StudentDocumentType;

  @Column({ name: 'object_key', type: 'varchar', length: 1024 })
  objectKey: string;

  @Column({ name: 'file_name', type: 'varchar', length: 255 })
  fileName: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
