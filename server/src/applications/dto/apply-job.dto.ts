import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';

export class ApplyJobDto {
  @ApiProperty({
    required: false,
    type: [String],
    maxItems: 5,
    description:
      'รหัสเอกสารจากคลังของตัวเองที่เลือกแนบ CV แนบเสมอ; เว้นว่างหรือ [] เพื่อแนบเฉพาะ CV ไม่แนบ transcript/เอกสารอื่นโดยอัตโนมัติ',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @ArrayUnique()
  @IsUUID('4', { each: true })
  documentIds?: string[];

  @ApiProperty({
    description: 'จดหมายแนะนำตัว (Cover Letter)',
    example:
      'ผมสนใจตำแหน่งนี้เนื่องจากมีทักษะตรงตามที่ระบุและอยากฝึกงานกับบริษัทนี้ครับ',
  })
  @IsString()
  @IsNotEmpty()
  coverLetter: string;
}
