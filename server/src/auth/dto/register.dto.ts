import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsEnum, IsString, MinLength } from 'class-validator';
import { UserRole } from '../user-role.js';

export class RegisterDto {
  @ApiProperty({ example: 'student@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({
    minLength: 8,
    example: 'Password123!',
    description:
      'อย่างน้อย 8 ตัวอักษร ไม่เกิน 72 ไบต์ UTF-8 มี A-Z, a-z, 0-9 และอักขระพิเศษ ASCII อย่างน้อยชนิดละ 1 ตัว (ไม่นับช่องว่าง)',
  })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiProperty({ enum: UserRole, example: UserRole.Student })
  @IsEnum(UserRole)
  role: UserRole;
}
