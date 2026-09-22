import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module.js';
import { CompanyJobsController } from './company-jobs.controller.js';
import { Job } from './entities/job.entity.js';
import { JobsController } from './jobs.controller.js';
import { JobsRepository } from './jobs.repository.js';
import { JobsService } from './jobs.service.js';

@Module({
  imports: [AuthModule, TypeOrmModule.forFeature([Job])],
  controllers: [CompanyJobsController, JobsController],
  providers: [JobsService, JobsRepository],
})
export class JobsModule {}
