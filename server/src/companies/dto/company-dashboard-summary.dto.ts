import { ApiProperty } from '@nestjs/swagger';

export class CompanyDashboardSummaryDto {
  @ApiProperty({
    example: 5,
    description: 'จำนวนประกาศทั้งหมดของบริษัท',
  })
  totalJobs: number;

  @ApiProperty({
    example: 3,
    description: 'จำนวนประกาศที่เปิดรับสมัครอยู่',
  })
  openJobs: number;

  @ApiProperty({
    example: 12,
    description: 'จำนวนผู้สมัครทั้งหมดในทุกประกาศของบริษัท',
  })
  totalApplicants: number;

  @ApiProperty({
    type: 'integer', minimum: 0, example: 7,
    description: 'จำนวนใบสมัครที่รอตรวจ สถานะ submitted หรือ reviewing ในทุกประกาศของบริษัท (รวมประกาศที่ปิดแล้ว)',
  })
  pendingApplicants: number;
}
