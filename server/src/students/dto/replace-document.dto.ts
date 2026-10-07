import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsUUID } from 'class-validator';

export class ReplaceDocumentDto {
  @ApiPropertyOptional({ description: 'ID of this student’s other document to replace atomically; omit to add a file', format: 'uuid' })
  @IsOptional()
  @IsUUID()
  documentId?: string;
}
