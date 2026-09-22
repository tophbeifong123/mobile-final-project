import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { AuthRepository } from './auth.repository.js';
import { AuthService } from './auth.service.js';
import { PASSWORD_HASHER } from './password-hasher.js';
import { UserRole } from './user-role.js';

describe('AuthService', () => {
  const repository = {
    findByEmail: vi.fn(),
    createUserWithProfile: vi.fn(),
    saveRefreshToken: vi.fn(),
    rotateRefreshToken: vi.fn(),
    revokeAllForUser: vi.fn(),
  };
  const jwtService = { signAsync: vi.fn() };
  const passwords = { hash: vi.fn(), verify: vi.fn() };
  const config = {
    get: vi.fn((_key: string, fallback?: string) => fallback ?? '7d'),
  };

  let service: AuthService;

  beforeEach(async () => {
    vi.clearAllMocks();
    jwtService.signAsync.mockResolvedValue('access-token');
    passwords.hash.mockResolvedValue('hashed-password');
    repository.saveRefreshToken.mockResolvedValue(undefined);

    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: AuthRepository, useValue: repository },
        { provide: JwtService, useValue: jwtService },
        { provide: PASSWORD_HASHER, useValue: passwords },
        { provide: ConfigService, useValue: config },
      ],
    }).compile();

    service = module.get(AuthService);
  });

  it('registers a student and returns a session', async () => {
    repository.findByEmail.mockResolvedValue(null);
    repository.createUserWithProfile.mockResolvedValue({
      id: 'user-1',
      email: 'student@example.com',
      role: UserRole.Student,
      passwordHash: 'hashed-password',
    });

    const result = await service.register({
      email: 'Student@Example.com',
      password: 'password123',
      role: UserRole.Student,
    });

    expect(repository.createUserWithProfile).toHaveBeenCalledWith({
      email: 'student@example.com',
      passwordHash: 'hashed-password',
      role: UserRole.Student,
    });
    expect(result.accessToken).toBe('access-token');
    expect(result.role).toBe(UserRole.Student);
    expect(result.refreshToken.length).toBeGreaterThan(20);
    expect(jwtService.signAsync).toHaveBeenCalledWith({
      sub: 'user-1',
      role: UserRole.Student,
    });
  });

  it('rejects a duplicate email', async () => {
    repository.findByEmail.mockResolvedValue({ id: 'user-1' });

    await expect(
      service.register({
        email: 'student@example.com',
        password: 'password123',
        role: UserRole.Student,
      }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(repository.createUserWithProfile).not.toHaveBeenCalled();
  });

  it('rejects login when the password is wrong', async () => {
    repository.findByEmail.mockResolvedValue({
      id: 'user-1',
      email: 'student@example.com',
      passwordHash: 'hashed-password',
      role: UserRole.Student,
    });
    passwords.verify.mockResolvedValue(false);

    await expect(
      service.login({
        email: 'student@example.com',
        password: 'wrong-password',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(repository.saveRefreshToken).not.toHaveBeenCalled();
  });
});
