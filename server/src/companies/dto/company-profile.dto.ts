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
}
