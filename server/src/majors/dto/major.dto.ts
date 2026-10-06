import { ApiProperty } from '@nestjs/swagger';

export class MajorDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'วิศวกรรมคอมพิวเตอร์' })
  nameTh: string;
}
