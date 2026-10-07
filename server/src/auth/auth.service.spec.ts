import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { AuthRepository } from './auth.repository.js';
import { AuthService } from './auth.service.js';
import { PASSWORD_HASHER } from './password-hasher.js';
import { GOOGLE_TOKEN_VERIFIER } from './google-token-verifier.js';
import { UserRole } from './user-role.js';

describe('AuthService', () => {
  const repository = {
    findByEmail: vi.fn(),
    findByGoogleSubject: vi.fn(),
    createUserWithProfile: vi.fn(),
    createGoogleUserWithProfile: vi.fn(),
    linkGoogleIdentity: vi.fn(),
    saveRefreshToken: vi.fn(),
    rotateRefreshToken: vi.fn(),
    revokeAllForUser: vi.fn(),
  };
  const jwtService = { signAsync: vi.fn() };
  const passwords = { hash: vi.fn(), verify: vi.fn() };
  const config = {
    get: vi.fn((_key: string, fallback?: string) => fallback ?? '7d'),
  };
  const googleTokens = {
    verify: vi.fn().mockResolvedValue({
      subject: 'google-sub-1',
      email: 'new@example.com',
      name: 'Google Student',
    }),
  };

  let service: AuthService;

  beforeEach(async () => {
    vi.resetAllMocks();
    jwtService.signAsync.mockResolvedValue('access-token');
    passwords.hash.mockResolvedValue('hashed-password');
    repository.saveRefreshToken.mockResolvedValue(true);
    googleTokens.verify.mockResolvedValue({
      subject: 'google-sub-1',
      email: 'new@example.com',
      name: 'Google Student',
    });
    config.get.mockImplementation(
      (_key: string, fallback?: string) => fallback ?? '7d',
    );

    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: AuthRepository, useValue: repository },
        { provide: JwtService, useValue: jwtService },
        { provide: PASSWORD_HASHER, useValue: passwords },
        { provide: ConfigService, useValue: config },
        { provide: GOOGLE_TOKEN_VERIFIER, useValue: googleTokens },
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
      fullName: '  มีนา  ',
      email: 'Student@Example.com',
      password: 'Password123!',
      role: UserRole.Student,
    });

    expect(repository.createUserWithProfile).toHaveBeenCalledWith({
      email: 'student@example.com',
      passwordHash: 'hashed-password',
      role: UserRole.Student,
      fullName: 'มีนา',
    });
    expect(result.accessToken).toBe('access-token');
    expect(result.role).toBe(UserRole.Student);
    expect(result.refreshToken.length).toBeGreaterThan(20);
    expect(jwtService.signAsync).toHaveBeenCalledWith({
      sub: 'user-1',
      role: UserRole.Student,
      tokenVersion: 0,
    });
  });

  it('rejects a duplicate email', async () => {
    repository.findByEmail.mockResolvedValue({ id: 'user-1' });

    await expect(
      service.register({
        fullName: 'มีนา',
        email: 'student@example.com',
        password: 'Password123!',
        role: UserRole.Student,
      }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(repository.createUserWithProfile).not.toHaveBeenCalled();
  });

  it.each([UserRole.Student, UserRole.Company])(
    'rejects a weak signup password before hashing for %s',
    async (role) => {
      await expect(
        service.register({
          fullName: 'มีนา',
          email: 'person@example.com',
          password: 'abcdefgh',
          role,
        }),
      ).rejects.toThrow('Bad Request');
      expect(passwords.hash).not.toHaveBeenCalled();
      expect(repository.createUserWithProfile).not.toHaveBeenCalled();
    },
  );

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

  it('rejects password login for an account without a password credential', async () => {
    repository.findByEmail.mockResolvedValue({
      id: 'google-user',
      email: 'student@example.com',
      passwordHash: null,
      role: UserRole.Student,
    });

    await expect(
      service.login({
        email: 'student@example.com',
        password: 'password123',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(passwords.verify).not.toHaveBeenCalled();
  });
  it('requires a role before creating a new Google account', async () => {
    repository.findByGoogleSubject.mockResolvedValue(null);
    repository.findByEmail.mockResolvedValue(null);

    await expect(
      service.googleAuth({ idToken: 'google-id-token' }),
    ).resolves.toEqual({
      code: 'role_required',
    });
    expect(repository.createGoogleUserWithProfile).not.toHaveBeenCalled();
  });

  it('creates a Google user and profile with the selected role', async () => {
    repository.findByGoogleSubject.mockResolvedValue(null);
    repository.findByEmail.mockResolvedValue(null);
    repository.createGoogleUserWithProfile.mockResolvedValue({
      id: 'google-user',
      email: 'new@example.com',
      passwordHash: null,
      role: UserRole.Company,
      fullName: 'Google Student',
    });

    const result = await service.googleAuth({
      idToken: 'google-id-token',
      role: UserRole.Company,
    });

    expect(repository.createGoogleUserWithProfile).toHaveBeenCalledWith({
      email: 'new@example.com',
      providerSubject: 'google-sub-1',
      role: UserRole.Company,
      fullName: 'Google Student',
    });
    expect(result).toMatchObject({
      accessToken: 'access-token',
      role: 'company',
    });
  });

  it('does not auto-link a Google identity to an existing password account', async () => {
    repository.findByGoogleSubject.mockResolvedValue(null);
    repository.findByEmail.mockResolvedValue({
      id: 'password-user',
      email: 'new@example.com',
      passwordHash: 'existing-hash',
      role: UserRole.Student,
    });

    await expect(
      service.googleAuth({
        idToken: 'google-id-token',
        role: UserRole.Student,
      }),
    ).rejects.toMatchObject({
      response: {
        code: 'password_link_required',
        email: 'new@example.com',
        message: 'อีเมลนี้มีบัญชีอยู่แล้ว กรอกรหัสผ่านเดิมเพื่อผูก Google',
      },
    });
    expect(repository.createGoogleUserWithProfile).not.toHaveBeenCalled();
    expect(repository.linkGoogleIdentity).not.toHaveBeenCalled();
  });

  it('links Google after the existing password is verified', async () => {
    repository.findByGoogleSubject.mockResolvedValue(null);
    repository.findByEmail.mockResolvedValue({
      id: 'password-user',
      email: 'new@example.com',
      passwordHash: 'existing-hash',
      role: UserRole.Student,
    });
    passwords.verify.mockResolvedValue(true);
    repository.linkGoogleIdentity.mockResolvedValue('linked');

    const result = await service.linkGooglePasswordAccount({
      idToken: 'google-id-token',
      password: 'password123',
    });

    expect(passwords.verify).toHaveBeenCalledWith(
      'password123',
      'existing-hash',
    );
    expect(repository.linkGoogleIdentity).toHaveBeenCalledWith(
      'password-user',
      'google-sub-1',
    );
    expect(repository.createGoogleUserWithProfile).not.toHaveBeenCalled();
    expect(result).toMatchObject({
      accessToken: 'access-token',
      role: 'student',
    });
  });

  it('does not link Google when the password is wrong', async () => {
    repository.findByGoogleSubject.mockResolvedValue(null);
    repository.findByEmail.mockResolvedValue({
      id: 'password-user',
      email: 'new@example.com',
      passwordHash: 'existing-hash',
      role: UserRole.Student,
    });
    passwords.verify.mockResolvedValue(false);

    await expect(
      service.linkGooglePasswordAccount({
        idToken: 'google-id-token',
        password: 'wrong-password',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(repository.linkGoogleIdentity).not.toHaveBeenCalled();
  });

  it('uses the stored role for an existing Google identity', async () => {
    repository.findByGoogleSubject.mockResolvedValue({
      id: 'google-user',
      email: 'new@example.com',
      passwordHash: null,
      role: UserRole.Company,
    });

    const result = await service.googleAuth({
      idToken: 'google-id-token',
      role: UserRole.Student,
    });

    expect(result).toMatchObject({
      accessToken: 'access-token',
      role: 'company',
    });
    expect(repository.createGoogleUserWithProfile).not.toHaveBeenCalled();
  });

  it('uses the current token version when issuing a login session', async () => {
    repository.findByEmail.mockResolvedValue({
      id: 'user-1',
      email: 'student@example.com',
      passwordHash: 'hashed-password',
      role: UserRole.Student,
      tokenVersion: 3,
    });
    passwords.verify.mockResolvedValue(true);

    const session = await service.login({
      email: ' Student@Example.com ',
      password: 'password123',
    });

    expect(repository.findByEmail).toHaveBeenCalledWith('student@example.com');
    expect(jwtService.signAsync).toHaveBeenCalledWith({
      sub: 'user-1',
      role: UserRole.Student,
      tokenVersion: 3,
    });
    expect(repository.saveRefreshToken).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'user-1',
        tokenVersion: 3,
      }),
    );
    expect(repository.saveRefreshToken.mock.calls[0][0].tokenHash).not.toBe(
      session.refreshToken,
    );
  });

  it('refuses a stale login if a password reset occurred before refresh storage', async () => {
    repository.findByEmail.mockResolvedValue({
      id: 'user-1',
      passwordHash: 'old-hash',
      role: UserRole.Student,
      tokenVersion: 0,
    });
    passwords.verify.mockResolvedValue(true);
    repository.saveRefreshToken.mockResolvedValue(false);

    await expect(
      service.login({
        email: 'student@example.com',
        password: 'old-password',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(repository.saveRefreshToken).toHaveBeenCalledWith(
      expect.objectContaining({ tokenVersion: 0 }),
    );
  });

  it('includes the user version supplied by atomic refresh rotation', async () => {
    repository.rotateRefreshToken.mockResolvedValue({
      userId: 'user-1',
      role: UserRole.Student,
      tokenVersion: 4,
    });

    const session = await service.refresh({
      refreshToken: 'previous-refresh-token',
    });

    expect(jwtService.signAsync).toHaveBeenCalledWith({
      sub: 'user-1',
      role: UserRole.Student,
      tokenVersion: 4,
    });
    expect(session.refreshToken).not.toBe('previous-refresh-token');
    expect(repository.rotateRefreshToken.mock.calls[0][0].currentHash).not.toBe(
      'previous-refresh-token',
    );
  });

  it('rejects a revoked refresh token without signing another access token', async () => {
    repository.rotateRefreshToken.mockResolvedValue(null);

    await expect(
      service.refresh({ refreshToken: 'revoked-refresh-token' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(jwtService.signAsync).not.toHaveBeenCalled();
  });
});
