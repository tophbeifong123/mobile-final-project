import { ApiProperty } from '@nestjs/swagger';
import { JobStatus } from '../job-enums.js';

export class CompanyJobItemDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ example: 'Flutter Mobile Developer Intern' })
  title: string;

  @ApiProperty({ enum: JobStatus, example: JobStatus.Open })
  status: JobStatus;

  @ApiProperty({ example: 0 })
  applicantCount: number;
}
