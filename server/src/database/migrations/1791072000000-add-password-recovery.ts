import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddPasswordRecovery1791072000000 implements MigrationInterface {
  name = 'AddPasswordRecovery1791072000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" ADD "token_version" integer NOT NULL DEFAULT 0`);
    await queryRunner.query(`
      CREATE TABLE "password_reset_tokens" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "token_hash" varchar(64) NOT NULL,
        "expires_at" timestamptz NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_password_reset_user" UNIQUE ("user_id"),
        CONSTRAINT "UQ_password_reset_hash" UNIQUE ("token_hash"),
        CONSTRAINT "FK_password_reset_user" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE
      )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "password_reset_tokens"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "token_version"`);
  }
}
