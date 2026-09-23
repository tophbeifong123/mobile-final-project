import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module.js';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { Job } from '../jobs/entities/job.entity.js';
import { ApplicationsController } from './applications.controller.js';
import { ApplicationsRepository } from './applications.repository.js';
import { ApplicationsService } from './applications.service.js';
import { ApplicationStatusEvent } from './entities/application-status-event.entity.js';
import { Application } from './entities/application.entity.js';

@Module({
  imports: [
    AuthModule,
    TypeOrmModule.forFeature([
      Application,
      ApplicationStatusEvent,
      StudentProfile,
      Job,
    ]),
  ],
  controllers: [ApplicationsController],
  providers: [ApplicationsService, ApplicationsRepository],
  exports: [ApplicationsService, ApplicationsRepository],
})
export class ApplicationsModule {}
