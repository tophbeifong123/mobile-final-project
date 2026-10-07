import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { StudentDocumentType } from '../../students/student-document.entity.js';

@Entity({ name: 'application_documents' })
export class ApplicationDocument {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'application_id', type: 'uuid' }) applicationId: string;
  @Column({ type: 'varchar', length: 16 }) type: StudentDocumentType;
  @Column({ name: 'file_name', type: 'varchar', length: 255 }) fileName: string;
  @Column({ name: 'object_key', type: 'varchar', length: 1024 })
  objectKey: string;
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
