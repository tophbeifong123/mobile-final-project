import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEmail, Matches, MaxLength } from 'class-validator';
import { PASSWORD_RECOVERY_EMAIL_MESSAGE, PASSWORD_RECOVERY_EMAIL_PATTERN } from '../password-recovery-email.js';

export class ForgotPasswordDto {
  @ApiProperty({
    example: 'student@email.psu.ac.th',
    description: PASSWORD_RECOVERY_EMAIL_MESSAGE,
    maxLength: 255,
    pattern: PASSWORD_RECOVERY_EMAIL_PATTERN.source,
  })
  @Transform(({ value }: { value: unknown }) => typeof value === 'string' ? value.trim().toLowerCase() : value)
  @IsEmail()
  @Matches(PASSWORD_RECOVERY_EMAIL_PATTERN, { message: PASSWORD_RECOVERY_EMAIL_MESSAGE })
  @MaxLength(255)
  email: string;
}
