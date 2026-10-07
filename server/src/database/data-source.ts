import 'reflect-metadata';
import { AddJobOpeningsAllowance1791840000000 } from './migrations/1791840000000-add-job-openings-allowance.js';
import { DataSource } from 'typeorm';
import { ApplicationStatusEvent } from '../applications/entities/application-status-event.entity.js';
import { Application } from '../applications/entities/application.entity.js';
import { AuthIdentity } from '../auth/entities/auth-identity.entity.js';
import { CompanyProfile } from '../auth/entities/company-profile.entity.js';
import { RefreshToken } from '../auth/entities/refresh-token.entity.js';
import { PasswordResetToken } from '../auth/entities/password-reset-token.entity.js';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { User } from '../auth/entities/user.entity.js';
import { Job } from '../jobs/entities/job.entity.js';
import { SavedJob } from '../jobs/entities/saved-job.entity.js';
import { Notification } from '../notifications/entities/notification.entity.js';
import { StudentDocument } from '../students/student-document.entity.js';
import { AddAvatarToStudentProfiles1759200000000 } from './migrations/1759200000000-add-avatar-to-student-profiles.js';
import { CreateStudentDocuments1759400000000 } from './migrations/1759400000000-create-student-documents.js';
import { AddResumeFileNameToApplications1759450000000 } from './migrations/1759450000000-add-resume-file-name-to-applications.js';
import { Province } from '../provinces/province.entity.js';
import { University } from '../universities/university.entity.js';
import { Major } from '../majors/major.entity.js';
import { AddCompanyOfficeLocation1791158400000 } from './migrations/1791158400000-add-company-office-location.js';
import { DropOfficePin1791744000000 } from './migrations/1791744000000-drop-office-pin.js';
import { AddAllowanceAmountAndJobCategories1791830400000 } from './migrations/1791830400000-add-allowance-amount-and-job-categories.js';
import { NormalizeAllowanceAmount1791850000000 } from './migrations/1791850000000-normalize-allowance-amount.js';
import { UniqueGoogleIdentityPerUser1791940000000 } from './migrations/1791940000000-unique-google-identity-per-user.js';
import { AddApplicationSelectionLinks1792000000000 } from './migrations/1792000000000-add-application-selection-links.js';
import { AddJobInterviewMode1792100000000 } from './migrations/1792100000000-add-job-interview-mode.js';
import { AddExamPassedAt1792200000000 } from './migrations/1792200000000-add-exam-passed-at.js';
import { AddGoogleAuthIdentities1759300000000 } from './migrations/1759300000000-add-google-auth-identities.js';
import { AddBioContactsPortfoliosToStudentProfiles1759100000000 } from './migrations/1759100000000-add-bio-contacts-portfolios-to-student-profiles.js';
import { AddDetailsAndCoverToCompanyProfiles1759300000000 } from './migrations/1759300000000-add-details-and-cover-to-company-profiles.js';
import { AddDraftStatusAndDeadlineToJobs1759400000000 } from './migrations/1759400000000-add-draft-status-and-deadline-to-jobs.js';
import { AddSkillsToJobs1759000000000 } from './migrations/1759000000000-add-skills-to-jobs.js';
import { CreateApplicationsTables1758800000000 } from './migrations/1758800000000-create-applications-tables.js';
import { CreateAuthTables1758556800000 } from './migrations/1758556800000-create-auth-tables.js';
import { CreateJobsTable1758600000000 } from './migrations/1758600000000-create-jobs-table.js';
import { CreateNotificationsTable1758900000000 } from './migrations/1758900000000-create-notifications-table.js';
import { CreateSavedJobsTable1758700000000 } from './migrations/1758700000000-create-saved-jobs.js';
import { AddPasswordRecovery1791072000000 } from './migrations/1791072000000-add-password-recovery.js';
import { AddStudentUniversityMaster1791244800000 } from './migrations/1791244800000-add-student-university-master.js';
import { AddStudentMajorMaster1791331200000 } from './migrations/1791331200000-add-student-major-master.js';

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
    AuthIdentity,
    RefreshToken,
    PasswordResetToken,
    StudentProfile,
    CompanyProfile,
    Job,
    SavedJob,
    Application,
    ApplicationStatusEvent,
    Notification,
    StudentDocument,
    Province,
    University,
    Major,
  ],
  migrations: [
    CreateAuthTables1758556800000,
    CreateJobsTable1758600000000,
    CreateSavedJobsTable1758700000000,
    CreateApplicationsTables1758800000000,
    CreateNotificationsTable1758900000000,
    AddSkillsToJobs1759000000000,
    AddBioContactsPortfoliosToStudentProfiles1759100000000,
    AddAvatarToStudentProfiles1759200000000,
    CreateStudentDocuments1759400000000,
    AddResumeFileNameToApplications1759450000000,
    AddGoogleAuthIdentities1759300000000,
    AddDetailsAndCoverToCompanyProfiles1759300000000,
    AddDraftStatusAndDeadlineToJobs1759400000000,
    AddPasswordRecovery1791072000000,
    AddCompanyOfficeLocation1791158400000,
    AddStudentUniversityMaster1791244800000,
    AddStudentMajorMaster1791331200000,
    DropOfficePin1791744000000,
    AddAllowanceAmountAndJobCategories1791830400000,
    AddJobOpeningsAllowance1791840000000,
    NormalizeAllowanceAmount1791850000000,
    UniqueGoogleIdentityPerUser1791940000000,
    AddApplicationSelectionLinks1792000000000,
    AddJobInterviewMode1792100000000,
    AddExamPassedAt1792200000000,
  ],
});
