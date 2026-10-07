import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Province } from '../../provinces/province.entity.js';

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

  @Column({ name: 'province_id', type: 'smallint', nullable: true })
  provinceId: number | null;

  @ManyToOne(() => Province, { nullable: true, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'province_id' })
  province: Province | null;

  @Column({ type: 'text', default: '' })
  location: string;

  @Column({ name: 'website_url', type: 'varchar', length: 1024, default: '' })
  websiteUrl: string;

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
