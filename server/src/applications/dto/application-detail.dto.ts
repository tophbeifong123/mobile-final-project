import { ApiProperty } from '@nestjs/swagger';
import { ApplicationStatus } from '../application-status.js';
import { ApplicationJobDetailDto } from './application-job-detail.dto.js';
import { TimelineEventDto } from './timeline-event.dto.js';

export class ApplicationDetailDto {
  @ApiProperty({ format: 'uuid', description: 'รหัสใบสมัคร' })
  id: string;

  @ApiProperty({ format: 'uuid', description: 'รหัสประกาศงาน' })
  jobId: string;

  @ApiProperty({ type: () => ApplicationJobDetailDto, description: 'ข้อมูลงาน' })
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

  @ApiProperty({
    type: () => [TimelineEventDto],
    description: 'Timeline ประวัติการเปลี่ยนสถานะ',
  })
  timeline: TimelineEventDto[];
}
