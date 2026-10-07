import { Injectable } from '@nestjs/common';
import { type ThrottlerStorage } from '@nestjs/throttler';
import { type RateLimitHit, RateLimitRepository } from './rate-limit.repository.js';

type ThrottlerStorageRecord = Awaited<ReturnType<ThrottlerStorage['increment']>>;

const CLEANUP_PROBABILITY = 0.01;

@Injectable()
export class RateLimitService implements ThrottlerStorage {
  constructor(
    private readonly repository: RateLimitRepository,
    private readonly random: () => number = Math.random,
  ) {}

  async hit(key: string, windowMs: number): Promise<RateLimitHit> {
    const result = await this.repository.hit(key, windowMs);
    if (this.random() < CLEANUP_PROBABILITY) {
      await this.repository.deleteExpired();
    }
    return result;
  }

  async increment(
    key: string,
    ttl: number,
    limit: number,
    _blockDuration: number,
    throttlerName: string,
  ): Promise<ThrottlerStorageRecord> {
    const { hits, secondsLeft } = await this.hit(
      `throttler:${throttlerName}:${key}`,
      ttl,
    );
    const isBlocked = hits > limit;
    return {
      totalHits: hits,
      timeToExpire: secondsLeft,
      isBlocked,
      timeToBlockExpire: isBlocked ? secondsLeft : 0,
    };
  }
}
