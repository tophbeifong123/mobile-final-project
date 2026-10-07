import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddCompanyContactLinks1791860000000 implements MigrationInterface {
  name = 'AddCompanyContactLinks1791860000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD COLUMN IF NOT EXISTS "contact_links" jsonb NOT NULL DEFAULT '[]'::jsonb`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN IF EXISTS "contact_links"`,
    );
  }
}
