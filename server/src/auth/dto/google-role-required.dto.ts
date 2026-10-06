import { ApiProperty } from '@nestjs/swagger';

export class GoogleRoleRequiredDto {
  @ApiProperty({ example: 'role_required' })
  code: 'role_required';
}
