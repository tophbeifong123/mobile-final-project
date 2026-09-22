import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { RefreshToken } from '../auth/entities/refresh-token.entity.js';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { User } from '../auth/entities/user.entity.js';
import { CreateAuthTables1758556800000 } from './migrations/1758556800000-create-auth-tables.js';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DATABASE_HOST ?? 'localhost',
  port: Number(process.env.DATABASE_PORT ?? 5432),
  username: process.env.DATABASE_USER ?? 'postgres',
  password: process.env.DATABASE_PASSWORD ?? 'postgres',
  database: process.env.DATABASE_NAME ?? 'mobile_project_db',
  synchronize: false,
  entities: [User, RefreshToken, StudentProfile, CompanyProfile],
  migrations: [CreateAuthTables1758556800000],
});
