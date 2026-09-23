import { ApiProperty } from '@nestjs/swagger';
import { ApplicationStatus } from '../application-status.js';

export class JobApplicantItemDto {
  @ApiProperty({
    format: 'uuid',
    example: '11111111-1111-1111-1111-111111111111',
    description: 'รหัสใบสมัคร',
  })
  applicationId: string;

  @ApiProperty({
    example: 'สมชาย เรียนดี',
    description: 'ชื่อ-นามสกุลผู้สมัคร',
  })
  fullName: string;

  @ApiProperty({
    example: 'มหาวิทยาลัยเกษตรศาสตร์',
    description: 'มหาวิทยาลัย',
  })
  university: string;

  @ApiProperty({
    example: 'วิทยาการคอมพิวเตอร์',
    description: 'สาขาวิชา',
  })
  major: string;

  @ApiProperty({
    enum: ApplicationStatus,
    example: ApplicationStatus.Submitted,
    description: 'สถานะใบสมัคร',
  })
  status: ApplicationStatus;

  @ApiProperty({
    example: 'มีความสนใจและตั้งใจจะฝึกงานตำแหน่งนี้มากครับ',
    description: 'Cover Letter ของผู้สมัคร',
  })
  coverLetter: string;

  @ApiProperty({
    example: '2026-09-23T12:00:00.000Z',
    description: 'วันเวลาที่ยื่นใบสมัคร',
  })
  createdAt: string;
}
