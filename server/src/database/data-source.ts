import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { ApplicationStatusEvent } from '../applications/entities/application-status-event.entity.js';
import { Application } from '../applications/entities/application.entity.js';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { RefreshToken } from '../auth/entities/refresh-token.entity.js';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { User } from '../auth/entities/user.entity.js';
import { Job } from '../jobs/entities/job.entity.js';
import { SavedJob } from '../jobs/entities/saved-job.entity.js';
import { Notification } from '../notifications/entities/notification.entity.js';
import { CreateApplicationsTables1758800000000 } from './migrations/1758800000000-create-applications-tables.js';
import { CreateAuthTables1758556800000 } from './migrations/1758556800000-create-auth-tables.js';
import { CreateJobsTable1758600000000 } from './migrations/1758600000000-create-jobs-table.js';
import { CreateNotificationsTable1758900000000 } from './migrations/1758900000000-create-notifications-table.js';
import { CreateSavedJobsTable1758700000000 } from './migrations/1758700000000-create-saved-jobs.js';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DATABASE_HOST ?? 'localhost',
  port: Number(process.env.DATABASE_PORT ?? 5432),
  username: process.env.DATABASE_USER ?? 'postgres',
  password: process.env.DATABASE_PASSWORD ?? 'postgres',
  database: process.env.DATABASE_NAME ?? 'mobile_project_db',
  synchronize: false,
  entities: [
    User,
    RefreshToken,
    StudentProfile,
    CompanyProfile,
    Job,
    SavedJob,
    Application,
    ApplicationStatusEvent,
    Notification,
  ],
  migrations: [
    CreateAuthTables1758556800000,
    CreateJobsTable1758600000000,
    CreateSavedJobsTable1758700000000,
    CreateApplicationsTables1758800000000,
    CreateNotificationsTable1758900000000,
  ],
});
