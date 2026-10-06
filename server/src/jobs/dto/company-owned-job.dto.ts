import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { JobStatus, WorkMode } from '../job-enums.js';

export class CompanyOwnedJobDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ example: 'Flutter Mobile Developer Intern' })
  title: string;

  @ApiProperty()
  description: string;

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
    example: 3,
    description: 'จำนวนรับ; null เมื่อไม่ได้ระบุ',
  })
  openings: number | null;

  @ApiPropertyOptional({ example: 8000, nullable: true })
  allowanceAmount: number | null;

  @ApiProperty()
  requirements: string;

  @ApiProperty({ type: [String], example: ['Flutter', 'Dart'] })
  skills: string[];

  @ApiProperty({ enum: JobStatus, example: JobStatus.Open })
  status: JobStatus;

  @ApiProperty({ example: 1 })
  version: number;

  @ApiProperty({ example: 0 })
  applicantCount: number;

  @ApiProperty({
    example: 0,
    description: 'ใบสมัครที่รอตรวจ สถานะ submitted หรือ reviewing',
  })
  pendingApplicantCount: number;

  @ApiPropertyOptional({ type: String, format: 'date-time', nullable: true })
  deadline: Date | null;
}
