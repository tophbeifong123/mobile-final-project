import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddJobInterviewMode1792100000000 implements MigrationInterface {
  name = 'AddJobInterviewMode1792100000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "interview_mode" AS ENUM ('online', 'on_site')`,
    );
    await queryRunner.query(
      `ALTER TABLE "jobs" ADD "interview_mode" "interview_mode"`,
    );
    await queryRunner.query(`
      UPDATE "jobs"
      SET "interview_mode" = CASE
        WHEN "work_mode" = 'on_site' THEN 'on_site'::"interview_mode"
        ELSE 'online'::"interview_mode"
      END
    `);
    await queryRunner.query(
      `ALTER TABLE "jobs" ALTER COLUMN "interview_mode" SET NOT NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "applications" DROP CONSTRAINT "applications_interview_pair"`,
    );
    await queryRunner.query(`
      ALTER TABLE "applications"
      ADD CONSTRAINT "applications_interview_pair" CHECK (
        ("interview_url" IS NULL AND "interview_starts_at" IS NULL)
        OR "interview_starts_at" IS NOT NULL
      )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE "applications"
      SET "interview_url" = NULL, "interview_starts_at" = NULL
      WHERE "interview_starts_at" IS NOT NULL AND "interview_url" IS NULL
    `);
    await queryRunner.query(
      `ALTER TABLE "applications" DROP CONSTRAINT "applications_interview_pair"`,
    );
    await queryRunner.query(`
      ALTER TABLE "applications"
      ADD CONSTRAINT "applications_interview_pair" CHECK (
        ("interview_url" IS NULL AND "interview_starts_at" IS NULL)
        OR ("interview_url" IS NOT NULL AND "interview_starts_at" IS NOT NULL)
      )
    `);
    await queryRunner.query(
      `ALTER TABLE "jobs" DROP COLUMN "interview_mode"`,
    );
    await queryRunner.query(`DROP TYPE "interview_mode"`);
  }
}
