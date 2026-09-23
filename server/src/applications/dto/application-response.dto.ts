import { ApiProperty } from '@nestjs/swagger';
import { ApplicationStatus } from '../application-status.js';

export class ApplicationResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  jobId: string;

  @ApiProperty({ format: 'uuid' })
  studentId: string;

  @ApiProperty()
  coverLetter: string;

  @ApiProperty()
  resumeObjectKey: string;

  @ApiProperty({
    enum: ApplicationStatus,
    example: ApplicationStatus.Submitted,
  })
  status: ApplicationStatus;

  @ApiProperty()
  createdAt: string;

  @ApiProperty()
  updatedAt: string;
}
