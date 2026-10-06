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
      ALTER TABLE "jobs"
      ADD CONSTRAINT "CHK_jobs_category"
      CHECK ("category" IN ('IT & Software', 'Design & UX/UI', 'Marketing', 'Data'))
    `);
    await queryRunner.query(
      `ALTER TABLE "jobs" ADD "allowance_amount" integer`,
    );
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
    await queryRunner.query(
      `ALTER TABLE "jobs" DROP CONSTRAINT "CHK_jobs_allowance_amount"`,
    );
    await queryRunner.query(
      `ALTER TABLE "jobs" DROP COLUMN "allowance_amount"`,
    );
    await queryRunner.query(
      `ALTER TABLE "jobs" DROP CONSTRAINT "CHK_jobs_category"`,
    );
  }
}
