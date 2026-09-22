import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min } from 'class-validator';
import { CreateJobDto } from './create-job.dto.js';

export class UpdateJobDto extends CreateJobDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  @Min(1)
  version: number;
}
