import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthRepository } from './auth.repository.js';
import { JwtStrategy } from './jwt.strategy.js';
import { UserRole } from './user-role.js';

describe('JwtStrategy session invalidation', () => {
  const repository = { findById: vi.fn() };
  let strategy: JwtStrategy;

  beforeEach(() => {
    vi.resetAllMocks();
    strategy = new JwtStrategy(
      new ConfigService({ JWT_SECRET: 'test-only-secret' }),
      repository as unknown as AuthRepository,
    );
  });

  it('accepts the current token version and uses the database role', async () => {
    repository.findById.mockResolvedValue({
      id: 'user-1',
      role: UserRole.Student,
      tokenVersion: 2,
    });

    expect(
      await strategy.validate({
        sub: 'user-1',
        role: UserRole.Company,
        tokenVersion: 2,
      }),
    ).toEqual({ userId: 'user-1', role: UserRole.Student });
    expect(repository.findById).toHaveBeenCalledWith('user-1');
  });

  it('rejects an access token issued before a password reset', async () => {
    repository.findById.mockResolvedValue({
      id: 'user-1',
      role: UserRole.Student,
      tokenVersion: 1,
    });

    await expect(
      strategy.validate({
        sub: 'user-1',
        role: UserRole.Student,
        tokenVersion: 0,
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('accepts a legacy token without a version only while the database version is zero', async () => {
    repository.findById.mockResolvedValue({
      id: 'user-1',
      role: UserRole.Student,
      tokenVersion: 0,
    });

    expect(
      await strategy.validate({ sub: 'user-1', role: UserRole.Student }),
    ).toEqual({ userId: 'user-1', role: UserRole.Student });
  });

  it('rejects a legacy token after a password reset increments the version', async () => {
    repository.findById.mockResolvedValue({
      id: 'user-1',
      role: UserRole.Student,
      tokenVersion: 1,
    });

    await expect(
      strategy.validate({ sub: 'user-1', role: UserRole.Student }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('rejects a token belonging to a deleted account', async () => {
    repository.findById.mockResolvedValue(null);

    await expect(
      strategy.validate({
        sub: 'deleted-user',
        role: UserRole.Student,
        tokenVersion: 0,
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
