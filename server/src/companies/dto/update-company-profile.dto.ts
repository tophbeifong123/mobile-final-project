import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class UpdateCompanyProfileDto {
  @ApiPropertyOptional({ example: 'Tech Corp', maxLength: 255 })
  @Transform(trimString)
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  name?: string;

  @ApiPropertyOptional({ example: 'เทคโนโลยีสารสนเทศ', maxLength: 255 })
  @Transform(trimString)
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  businessType?: string;

  @ApiPropertyOptional({ example: 'บริษัทพัฒนาซอฟต์แวร์และแอปพลิเคชัน' })
  @Transform(trimString)
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    type: 'integer',
    nullable: true,
    example: 90,
    description:
      'รหัสจังหวัดจาก GET /api/provinces; null เพื่อล้างจังหวัดและหมุด',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  provinceId?: number | null;

  @ApiPropertyOptional({
    example: 'ถนนกาญจนวนิช ต.คอหงส์ อ.หาดใหญ่',
    maxLength: 255,
    description: 'ที่อยู่สั้น ไม่รวมจังหวัด',
  })
  @Transform(trimString)
  @IsOptional()
  @IsString()
  @MaxLength(255)
  location?: string;

  @ApiPropertyOptional({
    type: Number,
    nullable: true,
    example: 7.0064,
    description: 'ส่งพร้อม longitude; ส่ง null ทั้งคู่เพื่อล้างหมุด',
  })
  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Min(-90)
  @Max(90)
  latitude?: number | null;

  @ApiPropertyOptional({
    type: Number,
    nullable: true,
    example: 100.5008,
    description: 'ส่งพร้อม latitude',
  })
  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Min(-180)
  @Max(180)
  longitude?: number | null;
}
