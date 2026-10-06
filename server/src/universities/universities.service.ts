import { BadRequestException, Injectable } from '@nestjs/common';
import { UniversityDto } from './dto/university.dto.js';
import { University } from './university.entity.js';
import { UniversitiesRepository } from './universities.repository.js';

@Injectable()
export class UniversitiesService {
  constructor(private readonly repository: UniversitiesRepository) {}

  async search(query = ''): Promise<UniversityDto[]> {
    if (query.length > 100) throw new BadRequestException('คำค้นหายาวเกินไป');
    return (await this.repository.search(query)).map(({ id, nameTh }) => ({ id, nameTh }));
  }

  async requireById(id: string): Promise<University> {
    const university = await this.repository.findById(id);
    if (!university) throw new BadRequestException('ไม่พบมหาวิทยาลัยที่เลือก');
    return university;
  }
}
