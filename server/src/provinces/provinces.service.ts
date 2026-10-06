import { BadRequestException, Injectable } from '@nestjs/common';
import { Province } from './province.entity.js';
import { ProvinceDto } from './dto/province.dto.js';
import { ProvincesRepository } from './provinces.repository.js';

@Injectable()
export class ProvincesService {
  constructor(private readonly provincesRepository: ProvincesRepository) {}

  async list(): Promise<ProvinceDto[]> {
    return (await this.provincesRepository.list()).map((province) => ({
      id: province.id,
      nameTh: province.nameTh,
      aliases: province.aliases,
    }));
  }

  async requireById(id: number): Promise<Province> {
    const province = await this.provincesRepository.findById(id);
    if (!province) {
      throw new BadRequestException('ไม่พบจังหวัดที่เลือก');
    }
    return province;
  }

  async resolveName(value: string): Promise<string> {
    const name = value.trim().replace(/^จังหวัด\s*/, '');
    const province = await this.provincesRepository.findByNameOrAlias(name);
    if (!province) {
      throw new BadRequestException('ไม่พบจังหวัดที่เลือก');
    }
    return province.nameTh;
  }
}
