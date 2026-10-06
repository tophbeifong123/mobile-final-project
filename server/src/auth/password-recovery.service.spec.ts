import { createHash } from 'node:crypto';
import {
  BadRequestException,
  ConflictException,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuthRepository } from './auth.repository.js';
import { PASSWORD_HASHER } from './password-hasher.js';
import {
  PASSWORD_RESET_REQUEST_MESSAGE,
  PasswordRecoveryService,
} from './password-recovery.service.js';
import { PasswordResetMailer } from './password-reset-mailer.js';

describe('PasswordRecoveryService', () => {
  const now = new Date('2026-10-04T12:00:00Z');
  const repository = {
    findByEmail: vi.fn(),
    findById: vi.fn(),
    replacePasswordResetToken: vi.fn(),
    findPasswordResetToken: vi.fn(),
    consumePasswordResetToken: vi.fn(),
    deletePasswordResetToken: vi.fn(),
  };
  const mailer = {
    assertConfigured: vi.fn(),
    sendResetLink: vi.fn(),
    sendPasswordChanged: vi.fn(),
  };
  const passwords = { hash: vi.fn(), verify: vi.fn() };
  const dto = { token: 'a'.repeat(64), password: 'a-new-strong-password' };
  const tokenHash = createHash('sha256').update(dto.token).digest('hex');
  let service: PasswordRecoveryService;

  beforeEach(async () => {
    vi.resetAllMocks();
    vi.useFakeTimers();
    vi.setSystemTime(now);
    vi.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
    repository.findByEmail.mockResolvedValue({
      id: 'user-1',
      email: 'student@email.psu.ac.th',
    });
    repository.findById.mockResolvedValue({
      id: 'user-1',
      email: 'student@email.psu.ac.th',
      passwordHash: 'current-password-hash',
    });
    repository.replacePasswordResetToken.mockResolvedValue(true);
    repository.findPasswordResetToken.mockResolvedValue({
      userId: 'user-1',
      expiresAt: new Date(now.getTime() + 60_000),
    });
    repository.consumePasswordResetToken.mockImplementation(
      async (
        _tokenHash: string,
        _passwordHash: string,
        isReusedPassword: (currentHash: string) => Promise<boolean>,
      ) =>
        (await isReusedPassword('current-password-hash'))
          ? { status: 'reused' }
          : { status: 'consumed', email: 'student@email.psu.ac.th' },
    );
    repository.deletePasswordResetToken.mockResolvedValue(undefined);
    mailer.sendResetLink.mockResolvedValue(undefined);
    mailer.sendPasswordChanged.mockResolvedValue(undefined);
    passwords.hash.mockResolvedValue('secure-password-hash');
    passwords.verify.mockResolvedValue(false);
    const module = await Test.createTestingModule({
      providers: [
        PasswordRecoveryService,
        { provide: AuthRepository, useValue: repository },
        { provide: PasswordResetMailer, useValue: mailer },
        { provide: PASSWORD_HASHER, useValue: passwords },
      ],
    }).compile();
    service = module.get(PasswordRecoveryService);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  async function request(email: string) {
    const result = service.forgotPassword({ email });
    await vi.advanceTimersByTimeAsync(200);
    return result;
  }

  it.each(['email.psu.ac.th', 'psu.ac.th', 'gmail.com', 'outlook.com', 'example.com'])(
    'returns the same generic message for registered and unknown accounts at %s',
    async (domain) => {
      repository.findByEmail.mockResolvedValue({ id: 'user-1', email: `known@${domain}` });
      const known = await request(`known@${domain}`);
      repository.findByEmail.mockResolvedValue(null);
      const unknown = await request(`unknown@${domain}`);

      expect(known).toEqual({ message: PASSWORD_RESET_REQUEST_MESSAGE });
      expect(unknown).toEqual(known);
      expect(repository.replacePasswordResetToken).toHaveBeenCalledTimes(1);
      expect(mailer.sendResetLink).toHaveBeenCalledTimes(1);
    },
  );

  it('normalizes email and stores only the SHA-256 hash of a random token expiring in 15 minutes', async () => {
    await request(' Student@Email.Psu.Ac.Th ');

    expect(repository.findByEmail).toHaveBeenCalledWith(
      'student@email.psu.ac.th',
    );
    const [email, plainToken] = mailer.sendResetLink.mock.calls[0];
    const stored = repository.replacePasswordResetToken.mock.calls[0][0];
    expect(email).toBe('student@email.psu.ac.th');
    expect(plainToken).toMatch(/^[a-f0-9]{64}$/);
    expect(stored).toEqual({
      userId: 'user-1',
      tokenHash: createHash('sha256').update(plainToken).digest('hex'),
      expiresAt: new Date(now.getTime() + 15 * 60_000),
    });
    expect(stored.tokenHash).not.toBe(plainToken);
  });

  it('does not disclose cooldown or send another email when issuance is denied', async () => {
    repository.replacePasswordResetToken.mockResolvedValue(false);

    expect(await request('student@email.psu.ac.th')).toEqual({
      message: PASSWORD_RESET_REQUEST_MESSAGE,
    });
    expect(mailer.sendResetLink).not.toHaveBeenCalled();
  });

  it('does not wait for SMTP delivery before responding', async () => {
    mailer.sendResetLink.mockReturnValue(new Promise<void>(() => undefined));

    expect(await request('student@email.psu.ac.th')).toEqual({
      message: PASSWORD_RESET_REQUEST_MESSAGE,
    });
  });

  it('invalidates only the undelivered token after SMTP failure without exposing failure to the requester', async () => {
    mailer.sendResetLink.mockRejectedValue(
      new Error('SMTP authentication failed'),
    );

    expect(await request('student@email.psu.ac.th')).toEqual({
      message: PASSWORD_RESET_REQUEST_MESSAGE,
    });
    const stored = repository.replacePasswordResetToken.mock.calls[0][0];
    expect(repository.deletePasswordResetToken).toHaveBeenCalledWith(
      stored.tokenHash,
    );
  });

  it('checks mail configuration before looking up any account', async () => {
    mailer.assertConfigured.mockImplementation(() => {
      throw new ServiceUnavailableException();
    });

    await expect(
      service.forgotPassword({ email: 'unknown@email.psu.ac.th' }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(repository.findByEmail).not.toHaveBeenCalled();
  });

  it.each(['student@email.psu.ac.th', 'faculty@psu.ac.th', 'student@gmail.com', 'company@outlook.com', 'student@example.com', 'faculty@department.psu.ac.th'])(
    'sends a link to the registered email regardless of domain: %s',
    async (email) => {
      repository.findByEmail.mockResolvedValue({ id: 'user-1', email });

      expect(await request(email)).toEqual({
        message: PASSWORD_RESET_REQUEST_MESSAGE,
      });
      expect(repository.findByEmail).toHaveBeenCalledWith(email);
      expect(mailer.sendResetLink).toHaveBeenCalledWith(
        email,
        expect.any(String),
      );
    },
  );

  it.each([
    'student@@example.com',
    '@example.com',
    'student@example',
    'student name@example.com',
    '',
  ])(
    'rejects malformed email %s before SMTP or account lookup',
    async (email) => {
      mailer.assertConfigured.mockImplementation(() => {
        throw new ServiceUnavailableException();
      });

      await expect(service.forgotPassword({ email })).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(mailer.assertConfigured).not.toHaveBeenCalled();
      expect(repository.findByEmail).not.toHaveBeenCalled();
      expect(repository.replacePasswordResetToken).not.toHaveBeenCalled();
      expect(mailer.sendResetLink).not.toHaveBeenCalled();
    },
  );

  it('rejects an unknown, replaced or previously consumed token before hashing a password', async () => {
    repository.findPasswordResetToken.mockResolvedValue(null);

    await expect(service.resetPassword(dto)).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(repository.findPasswordResetToken).toHaveBeenCalledWith(tokenHash);
    expect(passwords.verify).not.toHaveBeenCalled();
    expect(passwords.hash).not.toHaveBeenCalled();
    expect(repository.consumePasswordResetToken).not.toHaveBeenCalled();
    expect(mailer.sendPasswordChanged).not.toHaveBeenCalled();
  });

  it.each([0, -1])(
    'rejects a token expiring %i milliseconds from now',
    async (offset) => {
      repository.findPasswordResetToken.mockResolvedValue({
        userId: 'user-1',
        expiresAt: new Date(now.getTime() + offset),
      });

      await expect(service.resetPassword(dto)).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(passwords.verify).not.toHaveBeenCalled();
      expect(passwords.hash).not.toHaveBeenCalled();
      expect(repository.consumePasswordResetToken).not.toHaveBeenCalled();
    },
  );

  it('passes the password hash to atomic consumption and notifies only the account owner', async () => {
    await service.resetPassword(dto);

    expect(repository.findById).toHaveBeenCalledWith('user-1');
    expect(passwords.verify).toHaveBeenCalledWith(
      dto.password,
      'current-password-hash',
    );
    expect(passwords.hash).toHaveBeenCalledWith(dto.password);
    expect(repository.consumePasswordResetToken).toHaveBeenCalledWith(
      tokenHash,
      'secure-password-hash',
      expect.any(Function),
    );
    expect(mailer.sendPasswordChanged).toHaveBeenCalledWith(
      'student@email.psu.ac.th',
    );
    expect(mailer.sendResetLink).not.toHaveBeenCalled();
  });

  it('rejects the current password with HTTP 409 and leaves the reset token untouched', async () => {
    passwords.verify.mockResolvedValue(true);

    const error = await service
      .resetPassword(dto)
      .catch((failure: unknown) => failure);

    expect(error).toBeInstanceOf(ConflictException);
    expect((error as ConflictException).getStatus()).toBe(409);
    expect((error as ConflictException).getResponse()).toEqual({
      statusCode: 409,
      code: 'PASSWORD_REUSE',
      message: 'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม',
    });
    expect((error as ConflictException).message).toBe(
      'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม',
    );
    expect(passwords.verify).toHaveBeenCalledWith(
      dto.password,
      'current-password-hash',
    );
    expect(passwords.hash).toHaveBeenCalledExactlyOnceWith(dto.password);
    expect(
      repository.consumePasswordResetToken,
    ).toHaveBeenCalledExactlyOnceWith(
      tokenHash,
      'secure-password-hash',
      expect.any(Function),
    );
    expect(repository.deletePasswordResetToken).not.toHaveBeenCalled();
    expect(mailer.sendPasswordChanged).not.toHaveBeenCalled();
  });

  it('allows retrying the same valid token with a different password after a reuse rejection', async () => {
    passwords.verify.mockResolvedValueOnce(true).mockResolvedValueOnce(false);

    await expect(service.resetPassword(dto)).rejects.toBeInstanceOf(
      ConflictException,
    );
    expect(repository.consumePasswordResetToken).toHaveBeenCalledTimes(1);
    expect(repository.deletePasswordResetToken).not.toHaveBeenCalled();

    const corrected = { ...dto, password: 'different-new-password' };
    await expect(service.resetPassword(corrected)).resolves.toEqual(
      expect.objectContaining({ message: expect.any(String) }),
    );
    expect(passwords.verify).toHaveBeenLastCalledWith(
      corrected.password,
      'current-password-hash',
    );
    expect(passwords.hash).toHaveBeenCalledTimes(2);
    expect(passwords.hash).toHaveBeenLastCalledWith(corrected.password);
    expect(repository.findPasswordResetToken).toHaveBeenCalledTimes(2);
    expect(repository.findPasswordResetToken).toHaveBeenNthCalledWith(
      1,
      tokenHash,
    );
    expect(repository.findPasswordResetToken).toHaveBeenNthCalledWith(
      2,
      tokenHash,
    );
    expect(repository.consumePasswordResetToken).toHaveBeenCalledTimes(2);
    expect(repository.consumePasswordResetToken).toHaveBeenNthCalledWith(
      1,
      tokenHash,
      'secure-password-hash',
      expect.any(Function),
    );
    expect(repository.consumePasswordResetToken).toHaveBeenNthCalledWith(
      2,
      tokenHash,
      'secure-password-hash',
      expect.any(Function),
    );
    expect(mailer.sendPasswordChanged).toHaveBeenCalledExactlyOnceWith(
      'student@email.psu.ac.th',
    );
  });

  it.each(['student@gmail.com', 'company@outlook.com', 'faculty@department.psu.ac.th'])(
    'resets a valid token owned by any registered email: %s',
    async (email) => {
      repository.findById.mockResolvedValue({ id: 'user-1', email });
      repository.consumePasswordResetToken.mockResolvedValue({ status: 'consumed', email });
      await expect(service.resetPassword(dto)).resolves.toEqual(
        expect.objectContaining({ message: expect.any(String) }),
      );
      expect(repository.findById).toHaveBeenCalledWith('user-1');
      expect(passwords.verify).not.toHaveBeenCalled();
      expect(passwords.hash).toHaveBeenCalledWith(dto.password);
      expect(repository.consumePasswordResetToken).toHaveBeenCalledWith(tokenHash, 'secure-password-hash', expect.any(Function));
      expect(mailer.sendPasswordChanged).toHaveBeenCalledWith(email);
    },
  );

  it('rejects a valid token whose owner no longer exists before hashing or consumption', async () => {
    repository.findById.mockResolvedValue(null);

    await expect(service.resetPassword(dto)).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(passwords.verify).not.toHaveBeenCalled();
    expect(passwords.hash).not.toHaveBeenCalled();
    expect(repository.consumePasswordResetToken).not.toHaveBeenCalled();
    expect(mailer.sendPasswordChanged).not.toHaveBeenCalled();
  });

  it('rejects a reset that loses concurrent token consumption or expires during hashing', async () => {
    repository.consumePasswordResetToken.mockResolvedValue(null);

    await expect(service.resetPassword(dto)).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(mailer.sendPasswordChanged).not.toHaveBeenCalled();
  });

  it('does not roll back a successful reset when the notification email fails', async () => {
    mailer.sendPasswordChanged.mockRejectedValue(new Error('SMTP unavailable'));

    await expect(service.resetPassword(dto)).resolves.toEqual(
      expect.objectContaining({ message: expect.any(String) }),
    );
    expect(repository.consumePasswordResetToken).toHaveBeenCalledTimes(1);
    expect(repository.deletePasswordResetToken).not.toHaveBeenCalled();
  });
});
