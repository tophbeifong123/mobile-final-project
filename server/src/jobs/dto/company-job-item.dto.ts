import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { JobStatus, WorkMode } from '../job-enums.js';

export class CompanyJobItemDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ example: 'Flutter Mobile Developer Intern' })
  title: string;

  @ApiProperty({ enum: JobStatus, example: JobStatus.Open })
  status: JobStatus;

  @ApiProperty({ enum: WorkMode, example: WorkMode.Hybrid })
  workMode: WorkMode;

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
