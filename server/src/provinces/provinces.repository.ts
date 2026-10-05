import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Province } from './province.entity.js';

@Injectable()
export class ProvincesRepository {
  constructor(private readonly dataSource: DataSource) {}

  list(): Promise<Province[]> {
    return this.dataSource
      .getRepository(Province)
      .find({ order: { id: 'ASC' } });
  }

  findById(id: number): Promise<Province | null> {
    return this.dataSource.getRepository(Province).findOne({ where: { id } });
  }

  findByNameOrAlias(name: string): Promise<Province | null> {
    return this.dataSource
      .getRepository(Province)
      .createQueryBuilder('province')
      .where('province.name_th = :name OR :name = ANY(province.aliases)', {
        name,
      })
      .getOne();
  }
}
