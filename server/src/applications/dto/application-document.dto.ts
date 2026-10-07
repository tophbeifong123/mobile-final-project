import { ApiProperty } from '@nestjs/swagger';
import { StudentDocumentType } from '../../students/student-document.entity.js';
export class ApplicationDocumentDto {
  @ApiProperty({
    format: 'uuid',
    description: 'รหัสสำเนาเอกสารของใบสมัคร ไม่ใช่รหัสคลังเอกสาร',
  })
  id: string;
  @ApiProperty({ enum: StudentDocumentType }) type: string;
  @ApiProperty({ description: 'ชื่อไฟล์ ณ เวลาสมัคร' }) fileName: string;
}
