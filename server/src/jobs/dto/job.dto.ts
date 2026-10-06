import { ApiProperty } from '@nestjs/swagger';
import { JobStatus, WorkMode } from '../job-enums.js';

export class JobDto {
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

  @ApiProperty({
    type: Number,
    nullable: true,
    minimum: 1,
    maximum: 2147483647,
    example: 3,
    description: 'จำนวนรับ; null เมื่อไม่ได้ระบุ',
  })
  openings: number | null;

  @ApiProperty({
    type: Number,
    nullable: true,
    minimum: 0,
    maximum: 99999999.99,
    example: 8000,
    description:
      'จำนวนเบี้ยเลี้ยงเงินบาท ทศนิยมไม่เกิน 2 ตำแหน่ง; null เมื่อไม่ได้ระบุหรือไม่มีเบี้ยเลี้ยง',
  })
  allowanceAmount: number | null;

  @ApiProperty()
  requirements: string;

  @ApiProperty({ type: [String], example: ['Flutter', 'Dart'] })
  skills: string[];

  @ApiProperty({ enum: JobStatus, example: JobStatus.Open })
  status: JobStatus;

  @ApiProperty({ example: 1 })
  version: number;
}
