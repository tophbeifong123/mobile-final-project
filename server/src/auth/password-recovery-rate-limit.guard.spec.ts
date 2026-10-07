import { type ExecutionContext, HttpException } from '@nestjs/common';
import { type RateLimitService } from '../rate-limit/rate-limit.service.js';
import { PasswordRecoveryRateLimitGuard } from './password-recovery-rate-limit.guard.js';

class SharedBuckets {
  private readonly buckets = new Map<string, { hits: number; until: number }>();
  now = Date.parse('2026-10-04T12:00:00Z');

  hit(key: string, windowMs: number) {
    const bucket = this.buckets.get(key);
    const next =
      !bucket || bucket.until <= this.now
        ? { hits: 1, until: this.now + windowMs }
        : { hits: bucket.hits + 1, until: bucket.until };
    this.buckets.set(key, next);
    return Promise.resolve({
      hits: next.hits,
      secondsLeft: Math.max(1, Math.ceil((next.until - this.now) / 1000)),
    });
  }
}

describe('PasswordRecoveryRateLimitGuard', () => {
  let buckets: SharedBuckets;
  const response = { setHeader: vi.fn() };

  function guard() {
    return new PasswordRecoveryRateLimitGuard(
      buckets as unknown as RateLimitService,
    );
  }

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
    buckets = new SharedBuckets();
  });

  it('allows ten requests and rejects the eleventh with HTTP 429', async () => {
    const subject = guard();
    for (let count = 0; count < 10; count++)
      await expect(subject.canActivate(context())).resolves.toBe(true);
    expect(response.setHeader).not.toHaveBeenCalled();

    const error = await subject.canActivate(context()).catch((e) => e);
    expect(error).toBeInstanceOf(HttpException);
    expect((error as HttpException).getStatus()).toBe(429);
    expect(response.setHeader).toHaveBeenCalledWith('Retry-After', 300);
  });

  it('allows requests again when the fixed five-minute window expires', async () => {
    const subject = guard();
    for (let count = 0; count < 10; count++) await subject.canActivate(context());
    buckets.now += 5 * 60_000 - 1;
    await expect(subject.canActivate(context())).rejects.toThrow(HttpException);
    expect(response.setHeader).toHaveBeenCalledWith('Retry-After', 1);
    buckets.now += 1;

    await expect(subject.canActivate(context())).resolves.toBe(true);
  });

  it('keeps separate budgets for each IP and recovery endpoint', async () => {
    const subject = guard();
    for (let count = 0; count < 10; count++) await subject.canActivate(context());

    await expect(subject.canActivate(context('127.0.0.2'))).resolves.toBe(true);
    await expect(
      subject.canActivate(context('127.0.0.1', function resetPassword() {})),
    ).resolves.toBe(true);
  });

  it('shares one budget across replicas that use the same store', async () => {
    const first = guard();
    const second = guard();
    for (let count = 0; count < 5; count++) await first.canActivate(context());
    for (let count = 0; count < 5; count++) await second.canActivate(context());

    await expect(first.canActivate(context())).rejects.toThrow(HttpException);
    await expect(second.canActivate(context())).rejects.toThrow(HttpException);
  });
});
