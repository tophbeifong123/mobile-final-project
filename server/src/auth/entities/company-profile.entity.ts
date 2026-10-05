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

  @Column({ type: 'varchar', length: 255, default: '' })
  location: string;

  @Column({ type: 'double precision', nullable: true })
  latitude: number | null;

  @Column({ type: 'double precision', nullable: true })
  longitude: number | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
