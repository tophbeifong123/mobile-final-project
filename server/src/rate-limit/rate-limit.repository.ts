import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';

export interface RateLimitHit {
  hits: number;
  secondsLeft: number;
}

@Injectable()
export class RateLimitRepository {
  constructor(private readonly dataSource: DataSource) {}

  async hit(key: string, windowMs: number): Promise<RateLimitHit> {
    const rows: { hits: number; seconds_left: number }[] =
      await this.dataSource.query(
        `
        INSERT INTO "rate_limit_buckets" ("key", "hits", "expires_at")
        VALUES ($1, 1, now() + ($2::int * interval '1 millisecond'))
        ON CONFLICT ("key") DO UPDATE SET
          "hits" = CASE
            WHEN "rate_limit_buckets"."expires_at" <= now() THEN 1
            ELSE "rate_limit_buckets"."hits" + 1
          END,
          "expires_at" = CASE
            WHEN "rate_limit_buckets"."expires_at" <= now() THEN EXCLUDED."expires_at"
            ELSE "rate_limit_buckets"."expires_at"
          END
        RETURNING
          "hits",
          GREATEST(1, CEIL(EXTRACT(EPOCH FROM ("expires_at" - now()))))::int AS "seconds_left"
        `,
        [key, windowMs],
      );
    return { hits: rows[0].hits, secondsLeft: rows[0].seconds_left };
  }

  async deleteExpired(): Promise<void> {
    await this.dataSource.query(
      `DELETE FROM "rate_limit_buckets" WHERE "expires_at" < now()`,
    );
  }
}
