import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class NormalizeAllowanceAmount1791850000000 implements MigrationInterface {
  name = 'NormalizeAllowanceAmount1791850000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE "jobs"
      SET "allowance_amount" = NULL
      WHERE "allowance_amount" IS NOT NULL
        AND (
          "has_allowance" = false
          OR "allowance_amount" < 1
          OR "allowance_amount" > 1000000
          OR "allowance_amount" <> trunc("allowance_amount")
        )
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs"
      ALTER COLUMN "allowance_amount" TYPE integer
      USING ROUND("allowance_amount")::integer
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs" DROP CONSTRAINT IF EXISTS "jobs_allowance_amount_valid"
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs" DROP CONSTRAINT IF EXISTS "CHK_jobs_allowance_amount"
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs"
      ADD CONSTRAINT "CHK_jobs_allowance_amount"
      CHECK (
        "allowance_amount" IS NULL
        OR (
          "has_allowance" = true
          AND "allowance_amount" >= 1
          AND "allowance_amount" <= 1000000
        )
      )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "jobs" DROP CONSTRAINT IF EXISTS "CHK_jobs_allowance_amount"
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs"
      ALTER COLUMN "allowance_amount" TYPE numeric(10,2)
      USING "allowance_amount"::numeric(10,2)
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs"
      ADD CONSTRAINT "jobs_allowance_amount_valid"
      CHECK (
        "allowance_amount" IS NULL
        OR ("has_allowance" AND "allowance_amount" >= 0)
      )
    `);
  }
}
