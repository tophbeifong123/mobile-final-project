import { ApiProperty } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { ContactLinkDto } from './contact-link.dto.js';
import { PortfolioLinkDto } from './portfolio-link.dto.js';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class UpdateStudentProfileDto {
  @ApiProperty({ example: 'มีนา เพ็งชัย', maxLength: 255 })
  @Transform(trimString)
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  fullName: string;

  @ApiProperty({ format: 'uuid', nullable: true, required: false, description: 'ID จาก GET /api/universities; ส่ง null เพื่อล้างค่า' })
  @IsOptional()
  @IsUUID()
  universityId?: string | null;

  @ApiProperty({ example: 'สถาบันการศึกษาอื่น', maxLength: 255, nullable: true, required: false })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(255)
  customUniversityName?: string | null;

  @ApiProperty({ format: 'uuid', nullable: true, required: false, description: 'ID จาก GET /api/majors; ส่ง null เพื่อล้างค่า' })
  @IsOptional()
  @IsUUID()
  majorId?: string | null;

  @ApiProperty({ example: 'สาขาอื่น', maxLength: 255, nullable: true, required: false, description: 'ใช้เมื่อสาขาไม่มีในรายการ' })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(255)
  customMajorName?: string | null;

  @ApiProperty({ type: [String], example: ['Flutter', 'SQL'] })
  @Transform(({ value }: { value: unknown }) => {
    if (!Array.isArray(value)) {
      return value;
    }
    return value
      .map((item) => (typeof item === 'string' ? item.trim() : item))
      .filter((item) => item !== '');
  })
  @IsArray()
  @ArrayMaxSize(30)
  @IsString({ each: true })
  @MaxLength(100, { each: true })
  skills: string[];

  @ApiProperty({
    example: 'นักศึกษาชั้นปีที่ 4 มุ่งมั่นหาประสบการณ์ฝึกงานด้าน Flutter & Node.js',
    maxLength: 1000,
    required: false,
  })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(1000)
  bio?: string;

  @ApiProperty({
    type: () => [ContactLinkDto],
    required: false,
    example: [
      {
        platform: 'phone',
        label: 'เบอร์โทร',
        value: '0812345678',
      },
    ],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => ContactLinkDto)
  contactLinks?: ContactLinkDto[];

  @ApiProperty({
    type: () => [PortfolioLinkDto],
    required: false,
    example: [
      {
        title: 'InternFinder App',
        url: 'https://github.com/example/internfinder',
        description: 'แอปพลิเคชันค้นหาที่ฝึกงาน',
      },
    ],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => PortfolioLinkDto)
  portfolioLinks?: PortfolioLinkDto[];

  @ApiProperty({
    nullable: true,
    required: false,
    example: 'https://example.com',
  })
  @Transform(({ value }: { value: unknown }) => {
    if (value == null) {
      return null;
    }
    if (typeof value !== 'string') {
      return value;
    }
    const trimmed = value.trim();
    return trimmed.length === 0 ? null : trimmed;
  })
  @IsOptional()
  @IsUrl({ protocols: ['http', 'https'], require_protocol: true })
  @MaxLength(2048)
  portfolioUrl?: string | null;
}
