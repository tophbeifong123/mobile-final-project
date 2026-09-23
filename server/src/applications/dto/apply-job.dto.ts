import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class ApplyJobDto {
  @ApiProperty({
    description: 'จดหมายแนะนำตัว (Cover Letter)',
    example: 'ผมสนใจตำแหน่งนี้เนื่องจากมีทักษะตรงตามที่ระบุและอยากฝึกงานกับบริษัทนี้ครับ',
  })
  @IsString()
  @IsNotEmpty()
  coverLetter: string;
}
