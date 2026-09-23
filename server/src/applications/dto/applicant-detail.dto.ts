import { ApiProperty } from '@nestjs/swagger';
import { ApplicationStatus } from '../application-status.js';

export class ApplicantDetailDto {
  @ApiProperty({
    format: 'uuid',
    example: '11111111-1111-1111-1111-111111111111',
    description: 'รหัสใบสมัคร',
  })
  applicationId: string;

  @ApiProperty({
    format: 'uuid',
    example: '22222222-2222-2222-2222-222222222222',
    description: 'รหัสประกาศงาน',
  })
  jobId: string;

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
    type: [String],
    example: ['Flutter', 'Dart', 'Node.js'],
    description: 'ทักษะความสามารถ',
  })
  skills: string[];

  @ApiProperty({
    example: 'https://github.com/somchai',
    nullable: true,
    description: 'ลิงก์ผลงาน (Portfolio)',
  })
  portfolioUrl: string | null;

  @ApiProperty({
    example: 'resumes/student-123/resume.pdf',
    description: 'Object key ของ Resume ที่ใช้สมัคร',
  })
  resumeObjectKey: string;

  @ApiProperty({
    example: 'resume.pdf',
    nullable: true,
    description: 'ชื่อไฟล์ Resume',
  })
  resumeFileName: string | null;

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

  @ApiProperty({
    example: '2026-09-23T12:00:00.000Z',
    description: 'วันเวลาที่อัปเดตล่าสุด',
  })
  updatedAt: string;
}
