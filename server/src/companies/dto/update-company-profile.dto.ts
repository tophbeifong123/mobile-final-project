import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength } from 'class-validator';

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
}
