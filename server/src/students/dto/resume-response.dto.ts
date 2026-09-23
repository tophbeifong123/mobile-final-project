import { ApiProperty } from '@nestjs/swagger';

export class ResumeResponseDto {
  @ApiProperty({ example: 'my_resume.pdf' })
  fileName: string;

  @ApiProperty({ example: 'resumes/student-id/12345.pdf' })
  objectKey: string;
}
