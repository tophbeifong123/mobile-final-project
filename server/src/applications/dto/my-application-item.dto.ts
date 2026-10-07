import { ApiProperty } from '@nestjs/swagger';
import { ApplicationStatus } from '../application-status.js';

export class MyApplicationItemDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  jobId: string;

  @ApiProperty()
  jobTitle: string;

  @ApiProperty()
  companyName: string;

  @ApiProperty({
    enum: ApplicationStatus,
    example: ApplicationStatus.Submitted,
  })
  status: ApplicationStatus;

  @ApiProperty()
  coverLetter: string;

  @ApiProperty()
  resumeObjectKey: string;

  @ApiProperty()
  createdAt: string;

  @ApiProperty()
  updatedAt: string;

  @ApiProperty({ nullable: true })
  examUrl: string | null;

  @ApiProperty({ nullable: true, format: 'date-time' })
  examDeadline: string | null;

  @ApiProperty({ nullable: true, format: 'date-time' })
  examCompletedAt: string | null;

  @ApiProperty({ nullable: true, format: 'date-time' })
  examPassedAt: string | null;

  @ApiProperty({ nullable: true })
  interviewUrl: string | null;

  @ApiProperty({ nullable: true, format: 'date-time' })
  interviewStartsAt: string | null;
}
