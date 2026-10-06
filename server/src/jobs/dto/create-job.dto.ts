import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  Min,
  Max,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { WorkMode } from '../job-enums.js';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class CreateJobDto {
  @ApiProperty({ example: 'Flutter Mobile Developer Intern', maxLength: 255 })
  @Transform(trimString)
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  title: string;

  @ApiProperty({ example: 'ช่วยพัฒนาแอปมือถือกับทีม' })
  @Transform(trimString)
  @IsString()
  @MinLength(1)
  description: string;

  @ApiProperty({
    example: 'สงขลา',
    maxLength: 255,
    description:
      'ชื่อจังหวัดมาตรฐานหรือชื่อเรียกจาก GET /api/provinces; ระบบบันทึกชื่อมาตรฐาน',
  })
  @Transform(trimString)
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  province: string;

  @ApiProperty({ enum: WorkMode, example: WorkMode.Hybrid })
  @IsEnum(WorkMode)
  workMode: WorkMode;

  @ApiProperty({ example: 'IT & Software', maxLength: 255 })
  @Transform(trimString)
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  category: string;

  @ApiProperty({ example: true })
  @IsBoolean()
  hasAllowance: boolean;

  @ApiPropertyOptional({
    type: Number,
    nullable: true,
    minimum: 1,
    maximum: 2147483647,
    example: 3,
    description: 'จำนวนรับ เป็นจำนวนเต็มบวก; ไม่ระบุหรือ null ได้',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(2147483647)
  openings?: number | null;

  @ApiPropertyOptional({
    type: Number,
    nullable: true,
    minimum: 0,
    maximum: 99999999.99,
    example: 8000,
    description:
      'เบี้ยเลี้ยงเงินบาท ทศนิยมไม่เกิน 2 ตำแหน่ง; null ได้; hasAllowance=false ระบบล้างเป็น null',
  })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(99999999.99)
  allowanceAmount?: number | null;

  @ApiProperty({ example: 'กำลังศึกษาอยู่และใช้ Flutter ได้' })
  @Transform(trimString)
  @IsString()
  @MinLength(1)
  requirements: string;

  @ApiPropertyOptional({
    type: [String],
    example: ['Flutter', 'Dart', 'Git'],
    description: 'ทักษะที่เปิดรับสมัคร',
  })
  @Transform(({ value }: { value: unknown }) => {
    if (!Array.isArray(value)) {
      if (typeof value === 'string') {
        return value
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean);
      }
      return [];
    }
    return value
      .map((item) => (typeof item === 'string' ? item.trim() : item))
      .filter((item) => item !== '');
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @MaxLength(100, { each: true })
  skills?: string[];
}
