import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { UserRole } from '../user-role.js';

export class GoogleAuthDto {
  @ApiProperty({
    description: 'Google ID token returned by the native/Web sign-in flow',
    maxLength: 8192,
  })
  @IsString()
  @MinLength(20)
  @MaxLength(8192)
  idToken: string;

  @ApiPropertyOptional({
    enum: UserRole,
    description: 'Required only for a new Google account',
  })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}
