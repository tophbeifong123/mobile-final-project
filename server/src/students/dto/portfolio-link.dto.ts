import { ApiProperty } from '@nestjs/swagger';
import {
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  MinLength,
} from 'class-validator';

export class PortfolioLinkDto {
  @ApiProperty({ required: false, example: 'p1' })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({
    example: 'InternFinder Mobile App',
    description: 'ชื่อผลงาน / ชื่องาน',
  })
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  title: string;

  @ApiProperty({
    example: 'https://github.com/my-project',
    description: 'ลิงก์ผลงาน (URL)',
  })
  @IsString()
  @IsUrl({ protocols: ['http', 'https'], require_protocol: true })
  @MaxLength(2048)
  url: string;

  @ApiProperty({
    required: false,
    example: 'แอปพลิเคชันค้นหาที่ฝึกงาน พัฒนาด้วย Flutter & Node.js',
    description: 'คำอธิบายสั้นๆ เกี่ยวกับผลงาน',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}
