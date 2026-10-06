import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { University } from './university.entity.js';
import { UniversitiesController } from './universities.controller.js';
import { UniversitiesRepository } from './universities.repository.js';
import { UniversitiesService } from './universities.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([University])],
  controllers: [UniversitiesController],
  providers: [UniversitiesRepository, UniversitiesService],
  exports: [UniversitiesService, UniversitiesRepository],
})
export class UniversitiesModule {}
