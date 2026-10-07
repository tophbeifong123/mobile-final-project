import { ApiProperty } from '@nestjs/swagger';
import { ContactLinkDto } from '../../students/dto/contact-link.dto.js';

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

  @ApiProperty({ example: 'https://www.bitkub.com', default: '' })
  websiteUrl: string;

  @ApiProperty({
    type: () => [ContactLinkDto],
    description:
      'ช่องทางติดต่อที่บริษัทบันทึกเอง เช่น โทร อีเมล Line; ไม่ใช่อีเมลที่ใช้เข้าสู่ระบบ',
    default: [],
  })
  contactLinks: ContactLinkDto[];

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
