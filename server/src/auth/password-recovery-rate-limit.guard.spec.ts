import { type ExecutionContext, HttpException } from '@nestjs/common';
import { PasswordRecoveryRateLimitGuard } from './password-recovery-rate-limit.guard.js';

describe('PasswordRecoveryRateLimitGuard', () => {
  let guard: PasswordRecoveryRateLimitGuard;
  const response = { setHeader: vi.fn() };

  function context(ip = '127.0.0.1', handler = function forgotPassword() {}) {
    return {
      getHandler: () => handler,
      switchToHttp: () => ({
        getRequest: () => ({ ip, socket: { remoteAddress: '127.0.0.2' } }),
        getResponse: () => response,
      }),
    } as unknown as ExecutionContext;
  }

  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-10-04T12:00:00Z'));
    guard = new PasswordRecoveryRateLimitGuard();
  });

  afterEach(() => vi.useRealTimers());

  it('allows ten requests and rejects the eleventh with HTTP 429', () => {
    for (let count = 0; count < 10; count++)
      expect(guard.canActivate(context())).toBe(true);
    expect(response.setHeader).not.toHaveBeenCalled();

    try {
      guard.canActivate(context());
      throw new Error('Expected rate limit rejection');
    } catch (error) {
      expect(error).toBeInstanceOf(HttpException);
      expect((error as HttpException).getStatus()).toBe(429);
    }
    expect(response.setHeader).toHaveBeenCalledWith('Retry-After', 300);
  });

  it('allows requests again when the fixed five-minute window expires', () => {
    for (let count = 0; count < 10; count++) guard.canActivate(context());
    vi.advanceTimersByTime(5 * 60_000 - 1);
    expect(() => guard.canActivate(context())).toThrow(HttpException);
    expect(response.setHeader).toHaveBeenCalledWith('Retry-After', 1);
    vi.advanceTimersByTime(1);

    expect(guard.canActivate(context())).toBe(true);
  });

  it('keeps separate budgets for each IP and recovery endpoint', () => {
    for (let count = 0; count < 10; count++) guard.canActivate(context());

    expect(guard.canActivate(context('127.0.0.2'))).toBe(true);
    expect(
      guard.canActivate(context('127.0.0.1', function resetPassword() {})),
    ).toBe(true);
  });

  it('rejects new buckets after its memory limit and recovers after expiration', () => {
    for (let count = 0; count < 10_000; count++)
      guard.canActivate(context(`ip-${count}`));

    expect(() => guard.canActivate(context('new-ip'))).toThrow(HttpException);
    expect(response.setHeader).toHaveBeenCalledWith('Retry-After', 300);
    expect(guard.canActivate(context('ip-0'))).toBe(true);
    vi.advanceTimersByTime(5 * 60_000);
    expect(guard.canActivate(context('new-ip'))).toBe(true);
  });
});
