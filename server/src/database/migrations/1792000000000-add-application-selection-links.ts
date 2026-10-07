import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddApplicationSelectionLinks1792000000000
  implements MigrationInterface
{
  name = 'AddApplicationSelectionLinks1792000000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "applications"
        ADD COLUMN "exam_url" varchar(2048),
        ADD COLUMN "exam_deadline" timestamptz,
        ADD COLUMN "exam_completed_at" timestamptz,
        ADD COLUMN "interview_url" varchar(2048),
        ADD COLUMN "interview_starts_at" timestamptz
    `);
    await queryRunner.query(`
      ALTER TABLE "applications"
        ADD CONSTRAINT "applications_exam_pair" CHECK (
          ("exam_url" IS NULL AND "exam_deadline" IS NULL)
          OR ("exam_url" IS NOT NULL AND "exam_deadline" IS NOT NULL)
        ),
        ADD CONSTRAINT "applications_interview_pair" CHECK (
          ("interview_url" IS NULL AND "interview_starts_at" IS NULL)
          OR ("interview_url" IS NOT NULL AND "interview_starts_at" IS NOT NULL)
        ),
        ADD CONSTRAINT "applications_exam_completed_requires_exam" CHECK (
          "exam_completed_at" IS NULL OR "exam_url" IS NOT NULL
        )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "applications"
        DROP CONSTRAINT "applications_exam_completed_requires_exam",
        DROP CONSTRAINT "applications_interview_pair",
        DROP CONSTRAINT "applications_exam_pair",
        DROP COLUMN "interview_starts_at",
        DROP COLUMN "interview_url",
        DROP COLUMN "exam_completed_at",
        DROP COLUMN "exam_deadline",
        DROP COLUMN "exam_url"
    `);
  }
}
