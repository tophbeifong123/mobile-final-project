import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { ApplicationStatus } from '../application-status.js';

export class UpdateApplicationStatusDto {
  @ApiProperty({
    enum: ApplicationStatus,
    example: ApplicationStatus.Reviewing,
    description: 'สถานะใบสมัครใหม่',
  })
  @IsEnum(ApplicationStatus)
  status: ApplicationStatus;
}
