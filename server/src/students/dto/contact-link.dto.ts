import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class ContactLinkDto {
  @ApiProperty({ required: false, example: 'c1' })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({
    example: 'phone',
    description:
      'ประเภทช่องทางติดต่อ เช่น phone, email, line, linkedin, github, facebook, other',
  })
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  platform: string;

  @ApiProperty({
    required: false,
    example: 'เบอร์โทรศัพท์',
    description: 'ป้ายชื่อกำกับ',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  label?: string;

  @ApiProperty({
    example: '0812345678',
    description: 'ข้อมูลการติดต่อ เช่น เบอร์โทร, ID, หรือ URL',
  })
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  value: string;
}
