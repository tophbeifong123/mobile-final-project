import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Province } from './province.entity.js';
import { ProvincesController } from './provinces.controller.js';
import { ProvincesRepository } from './provinces.repository.js';
import { ProvincesService } from './provinces.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([Province])],
  controllers: [ProvincesController],
  providers: [ProvincesRepository, ProvincesService],
  exports: [ProvincesService],
})
export class ProvincesModule {}
