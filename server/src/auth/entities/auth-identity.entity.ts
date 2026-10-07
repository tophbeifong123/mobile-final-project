import {
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  Column,
} from 'typeorm';

@Entity('auth_identities')
@Index('UQ_auth_identities_provider_subject', ['provider', 'providerSubject'], {
  unique: true,
})
@Index('UQ_auth_identities_user_provider', ['userId', 'provider'], {
  unique: true,
})
export class AuthIdentity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ type: 'varchar', length: 32 })
  provider: string;

  @Column({ name: 'provider_subject', type: 'varchar', length: 255 })
  providerSubject: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
