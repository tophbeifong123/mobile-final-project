import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsISO8601, IsOptional, IsString, MaxLength } from 'class-validator';

export class SetInterviewLinkDto {
  @ApiPropertyOptional({
    example: 'https://meet.example/room',
    maxLength: 2048,
    description:
      'ลิงก์นัดเมื่อประกาศเป็นสัมภาษณ์ออนไลน์ สัมภาษณ์ออนไซต์ไม่ส่งลิงก์',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  url?: string;

  @ApiProperty({
    format: 'date-time',
    example: '2026-10-09T09:00:00.000Z',
    description: 'วันเวลาที่นัดสัมภาษณ์',
  })
  @IsISO8601()
  startsAt: string;
}
