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
}
