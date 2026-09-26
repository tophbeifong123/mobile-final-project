import { ApiProperty } from '@nestjs/swagger';

export class CompanyProfileDto {
  @ApiProperty({ example: 'Tech Corp' })
  name: string;

  @ApiProperty({ example: 'เทคโนโลยีสารสนเทศ' })
  businessType: string;

  @ApiProperty({ example: 'บริษัทพัฒนาซอฟต์แวร์และแอปพลิเคชัน' })
  description: string;

  @ApiProperty({
    nullable: true,
    example: 'company-logos/company-id/1758556800000-uuid.png',
  })
  logoObjectKey: string | null;

  @ApiProperty({ example: 'https://www.bitkub.com', default: '' })
  websiteUrl: string;

  @ApiProperty({ example: 'FYI Center กรุงเทพฯ', default: '' })
  location: string;

  @ApiProperty({ example: '201-500 คน', default: '' })
  companySize: string;

  @ApiProperty({
    example: ['💻 MacBook Pro ประจำตำแหน่ง', '🍱 ขนมและเครื่องดื่มฟรีไม่อั้น'],
    type: [String],
    default: [],
  })
  perks: string[];

  @ApiProperty({
    nullable: true,
    example: 'company-covers/company-id/1758556800000-uuid.png',
  })
  coverObjectKey: string | null;
}
