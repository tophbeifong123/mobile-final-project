import { ApiProperty } from '@nestjs/swagger';
import { InterviewMode, WorkMode } from '../../jobs/job-enums.js';

export class ApplicationJobDetailDto {
  @ApiProperty({ format: 'uuid', description: 'รหัสประกาศงาน' })
  id: string;

  @ApiProperty({ description: 'ตำแหน่งงาน' })
  title: string;

  @ApiProperty({ description: 'ชื่อบริษัท' })
  companyName: string;

  @ApiProperty({ description: 'จังหวัด' })
  province: string;

  @ApiProperty({ enum: WorkMode, description: 'รูปแบบการทำงาน' })
  workMode: WorkMode;

  @ApiProperty({ enum: InterviewMode, description: 'รูปแบบสัมภาษณ์ของประกาศ' })
  interviewMode: InterviewMode;

  @ApiProperty({ description: 'หมวดหมู่งาน' })
  category: string;

  @ApiProperty({ description: 'มีเบี้ยเลี้ยงหรือไม่' })
  hasAllowance: boolean;
}
