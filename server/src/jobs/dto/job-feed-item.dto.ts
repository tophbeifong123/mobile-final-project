import { ApiProperty } from '@nestjs/swagger';
import { JobStatus, WorkMode } from '../job-enums.js';

export class JobFeedItemDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ example: 'Flutter Mobile Developer Intern' })
  title: string;

  @ApiProperty({ example: 'InternFinder' })
  companyName: string;

  @ApiProperty({ example: 'สงขลา' })
  province: string;

  @ApiProperty({ enum: WorkMode })
  workMode: WorkMode;

  @ApiProperty({ example: 'IT & Software' })
  category: string;

  @ApiProperty()
  hasAllowance: boolean;

  @ApiProperty({ type: [String], example: ['Flutter', 'Dart'] })
  skills: string[];

  @ApiProperty({ enum: JobStatus, example: JobStatus.Open })
  status: JobStatus;
}
