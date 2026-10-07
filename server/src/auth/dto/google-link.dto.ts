import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class GoogleLinkDto {
  @ApiProperty({
    description: 'Google ID token for the account to link. The email is read from this token.',
    maxLength: 8192,
  })
  @IsString()
  @MinLength(20)
  @MaxLength(8192)
  idToken: string;

  @ApiProperty({
    description: 'Password of the existing InternFinder account with the same email',
  })
  @IsString()
  @MinLength(1)
  @MaxLength(1024)
  password: string;
}
