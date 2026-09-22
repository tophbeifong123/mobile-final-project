import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthController } from './auth.controller.js';
import { AuthRepository } from './auth.repository.js';
import { AuthService } from './auth.service.js';
import { CompanyProfile } from './entities/company-profile.entity.js';
import { RefreshToken } from './entities/refresh-token.entity.js';
import { StudentProfile } from './entities/student-profile.entity.js';
import { User } from './entities/user.entity.js';
import { JwtStrategy } from './jwt.strategy.js';
import { BcryptPasswordHasher, PASSWORD_HASHER } from './password-hasher.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      RefreshToken,
      StudentProfile,
      CompanyProfile,
    ]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const secret = config.get<string>('JWT_SECRET');
        if (!secret) {
          throw new Error('JWT_SECRET is required');
        }
        return {
          secret,
          signOptions: {
            expiresIn: durationSeconds(
              config.get<string>('JWT_ACCESS_EXPIRATION', '15m'),
              15 * 60,
            ),
          },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    AuthRepository,
    JwtStrategy,
    { provide: PASSWORD_HASHER, useClass: BcryptPasswordHasher },
  ],
})
export class AuthModule {}

function durationSeconds(value: string, fallbackSeconds: number): number {
  const match = /^(\d+)([smhd])$/.exec(value);
  if (!match) {
    return fallbackSeconds;
  }
  const amount = Number(match[1]);
  const unit = match[2];
  const multipliers: Record<string, number> = {
    s: 1,
    m: 60,
    h: 3_600,
    d: 86_400,
  };
  return amount * (multipliers[unit] ?? 0) || fallbackSeconds;
}
