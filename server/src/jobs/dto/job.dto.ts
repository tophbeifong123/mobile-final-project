import { ApiProperty } from '@nestjs/swagger';
import { JobStatus, WorkMode } from '../job-enums.js';

export class JobDto {
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

  @ApiProperty()
  requirements: string;

  @ApiProperty({ enum: JobStatus, example: JobStatus.Open })
  status: JobStatus;

  @ApiProperty({ example: 1 })
  version: number;
}
