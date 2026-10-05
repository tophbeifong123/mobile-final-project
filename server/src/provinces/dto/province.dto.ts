import { ApiProperty } from '@nestjs/swagger';

export class ProvinceDto {
  @ApiProperty({
    example: 10,
    description: 'รหัสจังหวัดตามมาตรฐานกรมการปกครอง',
  })
  id: number;

  @ApiProperty({ example: 'กรุงเทพมหานคร' })
  nameTh: string;

  @ApiProperty({ type: [String], example: ['กทม.', 'กรุงเทพฯ'] })
  aliases: string[];

  @ApiProperty({
    example: 13.753,
    description: 'ตำแหน่งประมาณสำหรับเปิดแผนที่ ไม่ใช่พิกัดสำนักงาน',
  })
  centerLatitude: number;

  @ApiProperty({ example: 100.5 })
  centerLongitude: number;
}
