import { ApiProperty } from '@nestjs/swagger';
import { ApplicationStatus } from '../application-status.js';

export class TimelineEventDto {
  @ApiProperty({ format: 'uuid', description: 'รหัส event' })
  id: string;

  @ApiProperty({
    enum: ApplicationStatus,
    nullable: true,
    description: 'สถานะก่อนหน้า',
  })
  fromStatus: ApplicationStatus | null;

  @ApiProperty({
    enum: ApplicationStatus,
    description: 'สถานะใหม่',
  })
  toStatus: ApplicationStatus;

  @ApiProperty({
    format: 'date-time',
    description: 'เวลาที่เกิด event',
  })
  createdAt: string;
}
