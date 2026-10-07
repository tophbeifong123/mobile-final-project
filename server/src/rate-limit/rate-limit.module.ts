import { Module } from '@nestjs/common';
import { RateLimitRepository } from './rate-limit.repository.js';
import { RateLimitService } from './rate-limit.service.js';

@Module({
  providers: [
    RateLimitRepository,
    {
      provide: RateLimitService,
      inject: [RateLimitRepository],
      useFactory: (repository: RateLimitRepository) =>
        new RateLimitService(repository),
    },
  ],
  exports: [RateLimitService],
})
export class RateLimitModule {}
