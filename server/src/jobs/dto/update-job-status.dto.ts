import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { JobStatus } from '../job-enums.js';

export class UpdateJobStatusDto {
  @ApiProperty({
    enum: JobStatus,
    example: JobStatus.Closed,
    description: 'สถานะประกาศใหม่ (draft, open หรือ closed)',
  })
  @IsEnum(JobStatus)
  status: JobStatus;
}
