import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  IsArray,
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
      'รหัสจังหวัดจาก GET /api/provinces; null เพื่อล้างจังหวัด',
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
    example: 'https://www.bitkub.com',
    required: false,
    maxLength: 1024,
    description:
      'เว็บไซต์ HTTP/HTTPS แบบเต็ม ไม่มี username/password; ส่งค่าว่างเพื่อล้างเว็บไซต์',
  })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(1024)
  websiteUrl?: string;

  @ApiPropertyOptional({ example: '201-500 คน' })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(100)
  companySize?: string;

  @ApiPropertyOptional({
    example: ['💻 MacBook Pro ประจำตำแหน่ง', '🍱 ขนมและเครื่องดื่มฟรีไม่อั้น'],
    type: [String],
    required: false,
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  perks?: string[];
}
