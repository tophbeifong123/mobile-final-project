import { ApiProperty } from '@nestjs/swagger';
import { IsISO8601, IsString, MaxLength } from 'class-validator';

export class SetExamLinkDto {
  @ApiProperty({
    example: 'https://exam.example/quiz',
    maxLength: 2048,
    description: 'ลิงก์ข้อสอบ HTTP หรือ HTTPS ที่ไม่มีชื่อผู้ใช้หรือรหัสผ่าน',
  })
  @IsString()
  @MaxLength(2048)
  url: string;

  @ApiProperty({
    format: 'date-time',
    example: '2026-10-08T12:00:00.000Z',
    description: 'กำหนดเวลาที่นักศึกษาทำข้อสอบได้',
  })
  @IsISO8601()
  deadline: string;
}
