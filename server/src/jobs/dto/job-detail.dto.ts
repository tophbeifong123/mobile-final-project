import { ApiProperty } from '@nestjs/swagger';
import { JobStatus, WorkMode } from '../job-enums.js';

export class JobDetailDto {
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

  @ApiProperty({ type: [String], example: ['Flutter', 'Dart'] })
  skills: string[];

  @ApiProperty({ enum: JobStatus, example: JobStatus.Open })
  status: JobStatus;

  @ApiProperty({ example: 'InternFinder' })
  companyName: string;

  @ApiProperty({ example: 'ซอฟต์แวร์' })
  businessType: string;

  @ApiProperty()
  companyDescription: string;

  @ApiProperty({
    example: 'https://example.com',
    description: 'เว็บไซต์ที่บันทึกในโปรไฟล์บริษัท; ค่าว่างเมื่อไม่ได้ระบุ',
  })
  companyWebsiteUrl: string;

  @ApiProperty({ example: '51-200', description: 'ขนาดองค์กรจากโปรไฟล์บริษัท' })
  companySize: string;

  @ApiProperty({ type: [String], example: ['MacBook', 'Free Lunch'] })
  companyPerks: string[];

  @ApiProperty({
    example: 'อาคาร A ถนนนิพัทธ์อุทิศ',
    description: 'ที่อยู่สำนักงานจาก location ในโปรไฟล์ ไม่ใช่จังหวัดของประกาศ',
  })
  companyLocation: string;

  @ApiProperty({
    description: 'มีโลโก้บริษัท; ดาวน์โหลดผ่าน GET /api/jobs/:id/company-logo',
  })
  companyLogoAvailable: boolean;

  @ApiProperty({ description: 'นักศึกษานี้บันทึกประกาศนี้ไว้แล้วหรือยัง' })
  saved: boolean;
}
