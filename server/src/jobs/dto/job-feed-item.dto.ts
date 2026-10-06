import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { JobStatus, WorkMode } from '../job-enums.js';

export class JobFeedItemDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ example: 'Flutter Mobile Developer Intern' })
  title: string;

  @ApiProperty({ example: 'InternFinder' })
  companyName: string;

  @ApiProperty({ type: String, format: 'date-time', description: 'วันเวลาสร้างประกาศ ไม่ใช่วันที่บันทึกงาน' })
  createdAt: Date;

  @ApiProperty({ description: 'โหลดโลโก้ผ่าน GET /api/jobs/:id/company-logo เมื่อเป็น true' })
  companyLogoAvailable: boolean;

  @ApiProperty({ example: 'สงขลา' })
  province: string;

  @ApiProperty({ enum: WorkMode })
  workMode: WorkMode;

  @ApiProperty({ example: 'IT & Software' })
  category: string;

  @ApiProperty()
  hasAllowance: boolean;

  @ApiProperty({
    type: Number,
    nullable: true,
    minimum: 1,
    maximum: 2147483647,
    example: 3,
    description: 'จำนวนรับ; null เมื่อไม่ได้ระบุ',
  })
  openings: number | null;

  @ApiPropertyOptional({ example: 8000, nullable: true })
  allowanceAmount: number | null;

  @ApiProperty({ type: [String], example: ['Flutter', 'Dart'] })
  skills: string[];

  @ApiProperty({ enum: JobStatus, example: JobStatus.Open })
  status: JobStatus;
}
