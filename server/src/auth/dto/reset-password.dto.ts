import { ApiProperty } from '@nestjs/swagger';
import { IsByteLength, IsString, Matches, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @ApiProperty({ description: 'Single-use token from the password reset email', minLength: 64, maxLength: 64 })
  @IsString()
  @Matches(/^[a-f0-9]{64}$/)
  token: string;

  @ApiProperty({ minLength: 8, description: 'New password: at least 8 Unicode characters, at most 72 UTF-8 bytes, with A-Z, a-z, 0-9 and an ASCII special character; must differ from the current password' })
  @IsString()
  @MinLength(8)
  @IsByteLength(8, 72)
  password: string;
}
