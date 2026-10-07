import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class CreateRateLimitBuckets1792300000000 implements MigrationInterface {
  name = 'CreateRateLimitBuckets1792300000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "rate_limit_buckets" (
        "key" varchar(255) PRIMARY KEY,
        "hits" integer NOT NULL,
        "expires_at" timestamptz NOT NULL
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "rate_limit_buckets_expires_at_idx"
        ON "rate_limit_buckets" ("expires_at")
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "rate_limit_buckets"`);
  }
}
