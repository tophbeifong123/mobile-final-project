import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddJobOpeningsAllowance1791840000000 implements MigrationInterface {
  name = 'AddJobOpeningsAllowance1791840000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE jobs
      ADD COLUMN openings integer NULL,
      ADD COLUMN allowance_amount numeric(10,2) NULL,
      ADD CONSTRAINT jobs_openings_positive CHECK (openings IS NULL OR openings > 0),
      ADD CONSTRAINT jobs_allowance_amount_valid CHECK (
        allowance_amount IS NULL OR (has_allowance AND allowance_amount >= 0)
      )`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE jobs
      DROP CONSTRAINT jobs_allowance_amount_valid,
      DROP CONSTRAINT jobs_openings_positive,
      DROP COLUMN allowance_amount,
      DROP COLUMN openings`);
  }
}
