import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto.js';
import { JOB_CATEGORIES } from '../job-categories.js';
import { WorkMode } from '../job-enums.js';

function emptyToUndefined({ value }: { value: unknown }): unknown {
  if (typeof value !== 'string') {
    return value;
  }
  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

export class JobFeedQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ example: 'flutter' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsString()
  @MaxLength(255)
  search?: string;

  @ApiPropertyOptional({
    example: 'สงขลา',
    description: 'ชื่อจังหวัดมาตรฐานหรือชื่อเรียกจาก GET /api/provinces',
  })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsString()
  @MaxLength(255)
  province?: string;

  @ApiPropertyOptional({ enum: WorkMode })
  @IsOptional()
  @IsEnum(WorkMode)
  workMode?: WorkMode;

  @ApiPropertyOptional({ example: 'IT & Software', enum: JOB_CATEGORIES })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsIn(JOB_CATEGORIES)
  category?: string;

  @ApiPropertyOptional({ example: true })
  @Transform(({ value }: { value: unknown }) => {
    if (value === 'true' || value === true) {
      return true;
    }
    if (value === 'false' || value === false) {
      return false;
    }
    return value;
  })
  @IsOptional()
  @IsBoolean()
  hasAllowance?: boolean;

  @ApiPropertyOptional({
    example: 'Flutter,SQL',
    description: 'กรองด้วยทักษะ (คั่นด้วยจุลภาค เช่น Flutter,SQL)',
  })
  @Transform(({ value }: { value: unknown }) => {
    if (value == null) return undefined;
    if (Array.isArray(value)) {
      const arr = value
        .map((s) => (typeof s === 'string' ? s.trim() : s))
        .filter(Boolean);
      return arr.length === 0 ? undefined : arr;
    }
    if (typeof value === 'string') {
      const arr = value
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
      return arr.length === 0 ? undefined : arr;
    }
    return undefined;
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  skills?: string[];
}
