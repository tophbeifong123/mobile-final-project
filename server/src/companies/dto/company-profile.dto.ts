import { ApiProperty } from '@nestjs/swagger';

export class CompanyProfileDto {
  @ApiProperty({ example: 'Tech Corp' })
  name: string;

  @ApiProperty({ example: 'เทคโนโลยีสารสนเทศ' })
  businessType: string;

  @ApiProperty({ example: 'บริษัทพัฒนาซอฟต์แวร์และแอปพลิเคชัน' })
  description: string;

  @ApiProperty({
    type: String,
    nullable: true,
    example: 'company-logos/company-id/1758556800000-uuid.png',
  })
  logoObjectKey: string | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    example: 90,
    description: 'รหัสจังหวัดตาม GET /api/provinces',
  })
  provinceId: number | null;

  @ApiProperty({
    type: String,
    nullable: true,
    example: 'สงขลา',
    description: 'ชื่อจังหวัดมาตรฐานเดียวกับตัวกรองงาน',
  })
  provinceName: string | null;

  @ApiProperty({ example: 'ถนนกาญจนวนิช ต.คอหงส์ อ.หาดใหญ่', maxLength: 255 })
  location: string;

  @ApiProperty({ type: Number, nullable: true, example: 7.0064 })
  latitude: number | null;

  @ApiProperty({ type: Number, nullable: true, example: 100.5008 })
  longitude: number | null;
}
