import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class CreateJobsTable1758600000000 implements MigrationInterface {
  name = 'CreateJobsTable1758600000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "work_mode" AS ENUM ('on_site', 'hybrid', 'remote')`,
    );
    await queryRunner.query(
      `CREATE TYPE "job_status" AS ENUM ('open', 'closed')`,
    );
    await queryRunner.query(`
      CREATE TABLE "jobs" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "company_id" uuid NOT NULL,
        "title" varchar(255) NOT NULL,
        "description" text NOT NULL,
        "province" varchar(255) NOT NULL,
        "work_mode" "work_mode" NOT NULL,
        "category" varchar(255) NOT NULL,
        "has_allowance" boolean NOT NULL,
        "requirements" text NOT NULL,
        "status" "job_status" NOT NULL DEFAULT 'open',
        "version" int NOT NULL DEFAULT 1,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "FK_jobs_company" FOREIGN KEY ("company_id") REFERENCES "company_profiles" ("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_jobs_company_id" ON "jobs" ("company_id")`,
    );
    await queryRunner.query(`
      CREATE INDEX "IDX_jobs_feed" ON "jobs" (
        "status",
        "province",
        "work_mode",
        "category",
        "has_allowance"
      )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "jobs"`);
    await queryRunner.query(`DROP TYPE "job_status"`);
    await queryRunner.query(`DROP TYPE "work_mode"`);
  }
}
