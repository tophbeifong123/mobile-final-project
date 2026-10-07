import { ApiProperty } from '@nestjs/swagger';
import { ApplicationDocumentDto } from './application-document.dto.js';
import { ApplicationStatus } from '../application-status.js';
import { ApplicationJobDetailDto } from './application-job-detail.dto.js';
import { TimelineEventDto } from './timeline-event.dto.js';

export class ApplicationDetailDto {
  @ApiProperty({
    type: [ApplicationDocumentDto],
    description: 'สำเนาเอกสารที่แนบตอนสมัคร',
  })
  documents: ApplicationDocumentDto[];
  @ApiProperty({ format: 'uuid', description: 'รหัสใบสมัคร' })
  id: string;

  @ApiProperty({ format: 'uuid', description: 'รหัสประกาศงาน' })
  jobId: string;

  @ApiProperty({
    type: () => ApplicationJobDetailDto,
    description: 'ข้อมูลงาน',
  })
  job: ApplicationJobDetailDto;

  @ApiProperty({
    enum: ApplicationStatus,
    description: 'สถานะปัจจุบันของใบสมัคร',
  })
  status: ApplicationStatus;

  @ApiProperty({ description: 'Cover Letter ที่ยื่น' })
  coverLetter: string;

  @ApiProperty({ description: 'Object key ของ Resume ที่ใช้สมัคร' })
  resumeObjectKey: string;

  @ApiProperty({
    format: 'date-time',
    description: 'เวลายื่นใบสมัคร',
  })
  createdAt: string;

  @ApiProperty({
    format: 'date-time',
    description: 'เวลาอัปเดตสถานะล่าสุด',
  })
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

  @ApiProperty({
    type: () => [TimelineEventDto],
    description: 'Timeline ประวัติการเปลี่ยนสถานะ',
  })
  timeline: TimelineEventDto[];
}
