import { BadRequestException, Injectable } from '@nestjs/common';
import { MajorDto } from './dto/major.dto.js';
import { Major } from './major.entity.js';
import { MajorsRepository } from './majors.repository.js';

@Injectable()
export class MajorsService {
  constructor(private readonly repository: MajorsRepository) {}

  async search(query = ''): Promise<MajorDto[]> {
    if (query.length > 100) throw new BadRequestException('คำค้นหายาวเกินไป');
    return (await this.repository.search(query)).map(({ id, nameTh }) => ({ id, nameTh }));
  }

  async requireById(id: string): Promise<Major> {
    const major = await this.repository.findById(id);
    if (!major) throw new BadRequestException('ไม่พบสาขาที่เลือก');
    return major;
  }
}
