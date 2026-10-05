import { ApiProperty } from '@nestjs/swagger';

export class PasswordRecoveryResponseDto {
  @ApiProperty({ description: 'Result message. The forgot-password response never reveals whether an account exists.' })
  message: string;
}
