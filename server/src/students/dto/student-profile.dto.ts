import { ApiProperty } from '@nestjs/swagger';

export class StudentProfileDto {
  @ApiProperty({ example: 'มีนา เพ็งชัย' })
  fullName: string;

  @ApiProperty({ example: 'มหาวิทยาลัยสงขลานครินทร์' })
  university: string;

  @ApiProperty({ example: 'วิทยาการคอมพิวเตอร์' })
  major: string;

  @ApiProperty({ type: [String], example: ['Flutter', 'SQL'] })
  skills: string[];

  @ApiProperty({ nullable: true, example: 'https://example.com' })
  portfolioUrl: string | null;
}
