import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { JOB_CATEGORIES } from '../job-categories.js';
import { InterviewMode, WorkMode } from '../job-enums.js';

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

  @ApiProperty({
    enum: InterviewMode,
    example: InterviewMode.Online,
    description: 'รูปแบบสัมภาษณ์ของประกาศนี้ ออนไลน์ใช้ลิงก์นัด ออนไซต์นัดที่สำนักงาน',
  })
  @IsEnum(InterviewMode)
  interviewMode: InterviewMode;

  @ApiProperty({ example: 'IT & Software', enum: JOB_CATEGORIES })
  @Transform(trimString)
  @IsString()
  @IsIn(JOB_CATEGORIES)
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
    example: 8000,
    nullable: true,
    description: 'จำนวนเงินบาท บังคับเมื่อมีเบี้ยเลี้ยง และต้องว่างเมื่อไม่มี',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(1_000_000)
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
