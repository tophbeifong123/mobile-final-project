import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsArray, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class UpdateCompanyProfileDto {
  @ApiProperty({ example: 'Tech Corp', maxLength: 255 })
  @Transform(trimString)
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  name: string;

  @ApiProperty({ example: 'เทคโนโลยีสารสนเทศ', maxLength: 255 })
  @Transform(trimString)
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  businessType: string;

  @ApiProperty({ example: 'บริษัทพัฒนาซอฟต์แวร์และแอปพลิเคชัน' })
  @Transform(trimString)
  @IsString()
  description: string;

  @ApiProperty({ example: 'https://www.bitkub.com', required: false })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(1024)
  websiteUrl?: string;

  @ApiProperty({ example: 'FYI Center กรุงเทพฯ', required: false })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  location?: string;

  @ApiProperty({ example: '201-500 คน', required: false })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(100)
  companySize?: string;

  @ApiProperty({
    example: ['💻 MacBook Pro ประจำตำแหน่ง', '🍱 ขนมและเครื่องดื่มฟรีไม่อั้น'],
    type: [String],
    required: false,
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  perks?: string[];
}
