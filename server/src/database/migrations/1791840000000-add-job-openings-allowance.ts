import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddJobOpeningsAllowance1791840000000 implements MigrationInterface {
  name = 'AddJobOpeningsAllowance1791840000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "jobs" ADD COLUMN IF NOT EXISTS "openings" integer
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs" DROP CONSTRAINT IF EXISTS "jobs_openings_positive"
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs"
      ADD CONSTRAINT "jobs_openings_positive"
      CHECK ("openings" IS NULL OR "openings" > 0)
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "jobs" DROP CONSTRAINT IF EXISTS "jobs_openings_positive"
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs" DROP COLUMN IF EXISTS "openings"
    `);
  }
}
