import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddBioContactsPortfoliosToStudentProfiles1759100000000
  implements MigrationInterface
{
  name = 'AddBioContactsPortfoliosToStudentProfiles1759100000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "student_profiles" ADD COLUMN IF NOT EXISTS "bio" text NOT NULL DEFAULT ''`,
    );
    await queryRunner.query(
      `ALTER TABLE "student_profiles" ADD COLUMN IF NOT EXISTS "contact_links" jsonb NOT NULL DEFAULT '[]'::jsonb`,
    );
    await queryRunner.query(
      `ALTER TABLE "student_profiles" ADD COLUMN IF NOT EXISTS "portfolio_links" jsonb NOT NULL DEFAULT '[]'::jsonb`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "student_profiles" DROP COLUMN IF EXISTS "portfolio_links"`,
    );
    await queryRunner.query(
      `ALTER TABLE "student_profiles" DROP COLUMN IF EXISTS "contact_links"`,
    );
    await queryRunner.query(
      `ALTER TABLE "student_profiles" DROP COLUMN IF EXISTS "bio"`,
    );
  }
}
