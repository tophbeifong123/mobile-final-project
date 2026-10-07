import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Major } from './major.entity.js';

@Injectable()
export class MajorsRepository {
  constructor(private readonly dataSource: DataSource) {}

  async search(query: string): Promise<Major[]> {
    const normalized = normalize(query);
    const repository = this.dataSource.getRepository(Major);
    if (!normalized) return repository.find({ order: { nameTh: 'ASC' } });

    return repository
      .createQueryBuilder('major')
      .where(
        `regexp_replace(lower(major.name_th), '[[:space:]]+', '', 'g') LIKE :query`,
        { query: `%${escapeLike(normalized)}%` },
      )
      .orderBy('major.name_th', 'ASC')
      .getMany();
  }

  findById(id: string): Promise<Major | null> {
    return this.dataSource.getRepository(Major).findOne({ where: { id } });
  }
}

function normalize(value: string): string {
  return value.trim().replace(/\s+/g, '').toLowerCase();
}

function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, '\\$&');
}
