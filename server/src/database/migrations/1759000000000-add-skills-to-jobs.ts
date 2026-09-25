import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddSkillsToJobs1759000000000 implements MigrationInterface {
  name = 'AddSkillsToJobs1759000000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "jobs" ADD COLUMN IF NOT EXISTS "skills" text[] NOT NULL DEFAULT '{}'`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_jobs_skills" ON "jobs" USING GIN ("skills")`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_jobs_skills"`);
    await queryRunner.query(`ALTER TABLE "jobs" DROP COLUMN "skills"`);
  }
}
