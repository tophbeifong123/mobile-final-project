import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEmail, MaxLength } from 'class-validator';
import { PASSWORD_RECOVERY_EMAIL_MESSAGE } from '../password-recovery-email.js';

export class ForgotPasswordDto {
  @ApiProperty({
    example: 'student@example.com',
    description: 'อีเมลที่ใช้สมัครสมาชิก ไม่จำกัดโดเมน สำหรับนักศึกษาและบริษัท',
    maxLength: 255,
    format: 'email',
  })
  @Transform(({ value }: { value: unknown }) => typeof value === 'string' ? value.trim().toLowerCase() : value)
  @IsEmail({}, { message: PASSWORD_RECOVERY_EMAIL_MESSAGE })
  @MaxLength(255)
  email: string;
}
