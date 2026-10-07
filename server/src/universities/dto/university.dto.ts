import { ApiProperty } from '@nestjs/swagger';

export class UniversityDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'มหาวิทยาลัยสงขลานครินทร์' })
  nameTh: string;
}
