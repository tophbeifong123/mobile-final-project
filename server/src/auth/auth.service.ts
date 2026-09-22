import { createHash, randomBytes } from 'node:crypto';
import {
  ConflictException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { QueryFailedError } from 'typeorm';
import { AuthRepository } from './auth.repository.js';
import { AuthSessionDto } from './dto/auth-session.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import { User } from './entities/user.entity.js';
import { PASSWORD_HASHER, type PasswordHasher } from './password-hasher.js';

const INVALID_CREDENTIALS = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
const DUPLICATE_EMAIL = 'อีเมลนี้ถูกใช้แล้ว';
const INVALID_REFRESH = 'refresh token ใช้ไม่ได้';

@Injectable()
export class AuthService {
  constructor(
    private readonly authRepository: AuthRepository,
    private readonly jwtService: JwtService,
    @Inject(PASSWORD_HASHER) private readonly passwords: PasswordHasher,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthSessionDto> {
    const email = normalizeEmail(dto.email);
    const existing = await this.authRepository.findByEmail(email);
    if (existing) {
      throw new ConflictException(DUPLICATE_EMAIL);
    }

    const passwordHash = await this.passwords.hash(dto.password);
    try {
      const user = await this.authRepository.createUserWithProfile({
        email,
        passwordHash,
        role: dto.role,
      });
      return await this.issueSession(user);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictException(DUPLICATE_EMAIL);
      }
      throw error;
    }
  }

  async login(dto: LoginDto): Promise<AuthSessionDto> {
    const email = normalizeEmail(dto.email);
    const user = await this.authRepository.findByEmail(email);
    const passwordMatches = user
      ? await this.passwords.verify(dto.password, user.passwordHash)
      : false;
    if (!user || !passwordMatches) {
      throw new UnauthorizedException(INVALID_CREDENTIALS);
    }
    return this.issueSession(user);
  }

  async refresh(dto: RefreshDto): Promise<AuthSessionDto> {
    const refreshToken = randomBytes(32).toString('base64url');
    const rotated = await this.authRepository.rotateRefreshToken({
      currentHash: hashRefreshToken(dto.refreshToken),
      nextHash: hashRefreshToken(refreshToken),
      expiresAt: this.refreshExpiry(),
    });
    if (!rotated) {
      throw new UnauthorizedException(INVALID_REFRESH);
    }

    const accessToken = await this.jwtService.signAsync({
      sub: rotated.userId,
      role: rotated.role,
    });
    return {
      accessToken,
      refreshToken,
      role: rotated.role,
    };
  }

  async logout(userId: string): Promise<void> {
    await this.authRepository.revokeAllForUser(userId);
  }

  private async issueSession(user: User): Promise<AuthSessionDto> {
    const accessToken = await this.jwtService.signAsync({
      sub: user.id,
      role: user.role,
    });
    const refreshToken = randomBytes(32).toString('base64url');
    await this.authRepository.saveRefreshToken({
      userId: user.id,
      tokenHash: hashRefreshToken(refreshToken),
      expiresAt: this.refreshExpiry(),
    });
    return {
      accessToken,
      refreshToken,
      role: user.role,
    };
  }

  private refreshExpiry(): Date {
    const configured = this.config.get<string>('JWT_REFRESH_EXPIRATION', '7d');
    return new Date(Date.now() + durationMs(configured, 7 * 24 * 60 * 60 * 1000));
  }
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function hashRefreshToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

function durationMs(value: string, fallbackMs: number): number {
  const match = /^(\d+)([smhd])$/.exec(value);
  if (!match) {
    return fallbackMs;
  }
  const amount = Number(match[1]);
  const unit = match[2];
  const multipliers: Record<string, number> = {
    s: 1000,
    m: 60_000,
    h: 3_600_000,
    d: 86_400_000,
  };
  return amount * (multipliers[unit] ?? 0) || fallbackMs;
}

function isUniqueViolation(error: unknown): boolean {
  if (!(error instanceof QueryFailedError)) {
    return false;
  }
  const driverError = error.driverError as { code?: string };
  return driverError.code === '23505';
}
