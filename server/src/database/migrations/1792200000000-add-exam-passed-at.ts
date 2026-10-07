import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddExamPassedAt1792200000000 implements MigrationInterface {
  name = 'AddExamPassedAt1792200000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "applications"
        ADD COLUMN "exam_passed_at" timestamptz
    `);
    await queryRunner.query(`
      ALTER TABLE "applications"
        ADD CONSTRAINT "applications_exam_passed_requires_completed" CHECK (
          "exam_passed_at" IS NULL OR "exam_completed_at" IS NOT NULL
        )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "applications"
        DROP CONSTRAINT "applications_exam_passed_requires_completed",
        DROP COLUMN "exam_passed_at"
    `);
  }
}
