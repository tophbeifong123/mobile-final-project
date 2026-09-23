import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { StorageModule } from '../storage/storage.module.js';
import { StudentsController } from './students.controller.js';
import { StudentsRepository } from './students.repository.js';
import { StudentsService } from './students.service.js';

@Module({
  imports: [AuthModule, StorageModule],
  controllers: [StudentsController],
  providers: [StudentsService, StudentsRepository],
})
export class StudentsModule {}
