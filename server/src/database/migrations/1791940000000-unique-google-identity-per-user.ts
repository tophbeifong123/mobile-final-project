import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class UniqueGoogleIdentityPerUser1791940000000
  implements MigrationInterface
{
  name = 'UniqueGoogleIdentityPerUser1791940000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_auth_identities_user_provider"
      ON "auth_identities" ("user_id", "provider")
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'DROP INDEX "UQ_auth_identities_user_provider"',
    );
  }
}
