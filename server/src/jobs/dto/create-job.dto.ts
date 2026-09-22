import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
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

  @ApiProperty({ example: 'สงขลา', maxLength: 255 })
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

  @ApiProperty({ example: 'กำลังศึกษาอยู่และใช้ Flutter ได้' })
  @Transform(trimString)
  @IsString()
  @MinLength(1)
  requirements: string;
}
