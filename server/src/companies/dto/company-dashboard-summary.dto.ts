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
}
