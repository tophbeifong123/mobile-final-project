import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('company_profiles')
export class CompanyProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', unique: true })
  userId: string;

  @Column({ type: 'varchar', length: 255, default: '' })
  name: string;

  @Column({
    name: 'logo_object_key',
    type: 'varchar',
    length: 1024,
    nullable: true,
  })
  logoObjectKey: string | null;

  @Column({ name: 'business_type', type: 'varchar', length: 255, default: '' })
  businessType: string;

  @Column({ type: 'text', default: '' })
  description: string;

  @Column({ name: 'website_url', type: 'varchar', length: 1024, default: '' })
  websiteUrl: string;

  @Column({ type: 'text', default: '' })
  location: string;

  @Column({ name: 'company_size', type: 'varchar', length: 100, default: '' })
  companySize: string;

  @Column({ type: 'text', array: true, default: '{}' })
  perks: string[];

  @Column({
    name: 'cover_object_key',
    type: 'varchar',
    length: 1024,
    nullable: true,
  })
  coverObjectKey: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
