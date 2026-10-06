import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddGoogleAuthIdentities1759300000000 implements MigrationInterface {
  name = 'AddGoogleAuthIdentities1759300000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE "users" ALTER COLUMN "password_hash" DROP NOT NULL',
    );
    await queryRunner.query(`
      CREATE TABLE "auth_identities" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "provider" varchar(32) NOT NULL,
        "provider_subject" varchar(255) NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_auth_identities_provider_subject" UNIQUE ("provider", "provider_subject"),
        CONSTRAINT "FK_auth_identities_user" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      'CREATE INDEX "IDX_auth_identities_user_id" ON "auth_identities" ("user_id")',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    const [{ count }] = await queryRunner.query(
      'SELECT count(*)::int AS count FROM "users" WHERE "password_hash" IS NULL',
    );
    if (count > 0) {
      throw new Error(
        'Cannot revert Google auth migration while passwordless accounts exist',
      );
    }
    await queryRunner.query('DROP TABLE "auth_identities"');
    await queryRunner.query(
      'ALTER TABLE "users" ALTER COLUMN "password_hash" SET NOT NULL',
    );
  }
}
