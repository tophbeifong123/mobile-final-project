import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AuthUser } from './auth-user.js';
import { AuthRepository } from './auth.repository.js';
import { UserRole } from './user-role.js';

interface AccessTokenPayload {
  sub: string;
  role: UserRole;
  tokenVersion?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService, private readonly repository: AuthRepository) {
    const secret = config.get<string>('JWT_SECRET');
    if (!secret) {
      throw new Error('JWT_SECRET is required');
    }
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: AccessTokenPayload): Promise<AuthUser> {
    const user = await this.repository.findById(payload.sub);
    if (!user || user.tokenVersion !== (payload.tokenVersion ?? 0)) {
      throw new UnauthorizedException('กรุณาเข้าสู่ระบบอีกครั้ง');
    }
    return { userId: user.id, role: user.role };
  }
}
