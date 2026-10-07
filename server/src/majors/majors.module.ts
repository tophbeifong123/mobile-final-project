import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Major } from './major.entity.js';
import { MajorsController } from './majors.controller.js';
import { MajorsRepository } from './majors.repository.js';
import { MajorsService } from './majors.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([Major])],
  controllers: [MajorsController],
  providers: [MajorsRepository, MajorsService],
  exports: [MajorsRepository, MajorsService],
})
export class MajorsModule {}
