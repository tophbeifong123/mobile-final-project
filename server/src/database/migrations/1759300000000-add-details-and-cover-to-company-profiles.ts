import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddDetailsAndCoverToCompanyProfiles1759300000000
  implements MigrationInterface
{
  name = 'AddDetailsAndCoverToCompanyProfiles1759300000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD COLUMN IF NOT EXISTS "website_url" varchar(1024) NOT NULL DEFAULT ''`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD COLUMN IF NOT EXISTS "location" text NOT NULL DEFAULT ''`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD COLUMN IF NOT EXISTS "company_size" varchar(100) NOT NULL DEFAULT ''`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD COLUMN IF NOT EXISTS "perks" text[] NOT NULL DEFAULT '{}'`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD COLUMN IF NOT EXISTS "cover_object_key" varchar(1024) NULL`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN IF EXISTS "cover_object_key"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN IF EXISTS "perks"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN IF EXISTS "company_size"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN IF EXISTS "location"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN IF EXISTS "website_url"`,
    );
  }
}
