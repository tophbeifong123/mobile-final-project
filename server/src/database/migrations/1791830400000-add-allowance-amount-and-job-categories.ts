import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddAllowanceAmountAndJobCategories1791830400000
  implements MigrationInterface
{
  name = 'AddAllowanceAmountAndJobCategories1791830400000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE "jobs"
      SET "category" = CASE
        WHEN "category" ILIKE '%design%' OR "category" ILIKE '%ux%' THEN 'Design & UX/UI'
        WHEN "category" ILIKE '%market%' THEN 'Marketing'
        WHEN "category" ILIKE '%data%' THEN 'Data'
        ELSE 'IT & Software'
      END
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs" DROP CONSTRAINT IF EXISTS "CHK_jobs_category"
    `);
    await queryRunner.query(`
      ALTER TABLE "jobs"
      ADD CONSTRAINT "CHK_jobs_category"
      CHECK ("category" IN ('IT & Software', 'Design & UX/UI', 'Marketing', 'Data'))
    `);
    await queryRunner.query(
      `ALTER TABLE "jobs" ADD COLUMN IF NOT EXISTS "allowance_amount" integer`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "jobs" DROP COLUMN IF EXISTS "allowance_amount"`,
    );
    await queryRunner.query(
      `ALTER TABLE "jobs" DROP CONSTRAINT IF EXISTS "CHK_jobs_category"`,
    );
  }
}
