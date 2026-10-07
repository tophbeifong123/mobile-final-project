import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { University } from './university.entity.js';

@Injectable()
export class UniversitiesRepository {
  constructor(private readonly dataSource: DataSource) {}

  async search(query: string): Promise<University[]> {
    const normalized = query.trim();
    if (!normalized) {
      return this.dataSource.getRepository(University).find({ order: { nameTh: 'ASC' } });
    }
    return this.dataSource.getRepository(University)
      .createQueryBuilder('university')
      .where(`
        regexp_replace(lower(university.name_th), '[[:space:].]+', '', 'g') LIKE :query
        OR EXISTS (
          SELECT 1 FROM unnest(university.aliases) AS alias
          WHERE regexp_replace(lower(alias), '[[:space:].]+', '', 'g') LIKE :query
        )
      `, { query: `%${escapeLike(normalized.replace(/[\s.]/g, '').toLowerCase())}%` })
      .orderBy('university.name_th', 'ASC')
      .getMany();
  }

  findById(id: string): Promise<University | null> {
    return this.dataSource.getRepository(University).findOne({ where: { id } });
  }
}

function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, '\\$&');
}
