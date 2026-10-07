import { type RateLimitRepository } from './rate-limit.repository.js';
import { RateLimitService } from './rate-limit.service.js';

describe('RateLimitService', () => {
  const repository = { hit: vi.fn(), deleteExpired: vi.fn() };

  beforeEach(() => vi.clearAllMocks());

  function service(random = () => 0.5) {
    return new RateLimitService(
      repository as unknown as RateLimitRepository,
      random,
    );
  }

  it('keys throttler buckets by throttler name and reports the remaining window', async () => {
    repository.hit.mockResolvedValue({ hits: 3, secondsLeft: 42 });

    await expect(
      service().increment('ip-1', 60_000, 10, 60_000, 'default'),
    ).resolves.toEqual({
      totalHits: 3,
      timeToExpire: 42,
      isBlocked: false,
      timeToBlockExpire: 0,
    });
    expect(repository.hit).toHaveBeenCalledWith('throttler:default:ip-1', 60_000);
  });

  it('blocks once hits pass the limit until the window ends', async () => {
    repository.hit.mockResolvedValue({ hits: 11, secondsLeft: 17 });

    await expect(
      service().increment('ip-1', 60_000, 10, 60_000, 'default'),
    ).resolves.toMatchObject({ isBlocked: true, timeToBlockExpire: 17 });
  });

  it('removes expired buckets on a small share of hits', async () => {
    repository.hit.mockResolvedValue({ hits: 1, secondsLeft: 60 });

    await service(() => 0.5).hit('key', 60_000);
    expect(repository.deleteExpired).not.toHaveBeenCalled();

    await service(() => 0.001).hit('key', 60_000);
    expect(repository.deleteExpired).toHaveBeenCalledTimes(1);
  });
});
