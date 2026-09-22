import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '../user-role.js';

export class AuthSessionDto {
  @ApiProperty()
  accessToken: string;

  @ApiProperty()
  refreshToken: string;

  @ApiProperty({ enum: UserRole })
  role: UserRole;
}
