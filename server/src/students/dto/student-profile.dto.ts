import { ApiProperty } from '@nestjs/swagger';
import { ContactLinkDto } from './contact-link.dto.js';
import { PortfolioLinkDto } from './portfolio-link.dto.js';

export class StudentProfileDto {
  @ApiProperty({ example: 'มีนา เพ็งชัย' })
  fullName: string;

  @ApiProperty({ example: 'มหาวิทยาลัยสงขลานครินทร์' })
  university: string;

  @ApiProperty({ example: 'วิทยาการคอมพิวเตอร์' })
  major: string;

  @ApiProperty({ type: [String], example: ['Flutter', 'SQL'] })
  skills: string[];

  @ApiProperty({
    example: 'นักศึกษาชั้นปีที่ 4 มุ่งมั่นหาประสบการณ์ฝึกงานด้าน Flutter & Node.js',
  })
  bio: string;

  @ApiProperty({
    type: () => [ContactLinkDto],
    example: [
      {
        platform: 'phone',
        label: 'เบอร์โทร',
        value: '0812345678',
      },
    ],
  })
  contactLinks: ContactLinkDto[];

  @ApiProperty({
    type: () => [PortfolioLinkDto],
    example: [
      {
        title: 'InternFinder App',
        url: 'https://github.com/example/internfinder',
        description: 'แอปพลิเคชันค้นหาที่ฝึกงาน',
      },
    ],
  })
  portfolioLinks: PortfolioLinkDto[];

  @ApiProperty({ nullable: true, example: 'https://example.com' })
  portfolioUrl: string | null;

  @ApiProperty({ nullable: true, example: 'my_resume.pdf' })
  resumeFileName: string | null;

  @ApiProperty({ nullable: true, example: 'resumes/student-id/12345.pdf' })
  resumeObjectKey: string | null;

  @ApiProperty({
    nullable: true,
    example: 'student-avatars/student-id/12345.png',
  })
  avatarObjectKey: string | null;
}

