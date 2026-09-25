import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddDraftStatusAndDeadlineToJobs1759400000000
  implements MigrationInterface
{
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TYPE "job_status" ADD VALUE 'draft'`);
    await queryRunner.query(
      `ALTER TABLE "jobs" ADD COLUMN "deadline" timestamptz NULL`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "jobs" DROP COLUMN "deadline"`);
    // Note: PostgreSQL cannot remove enum values without recreating the type
  }
}
