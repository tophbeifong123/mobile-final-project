import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class CreateSavedJobsTable1758700000000 implements MigrationInterface {
  name = 'CreateSavedJobsTable1758700000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "saved_jobs" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "student_id" uuid NOT NULL,
        "job_id" uuid NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_saved_jobs_student_job" UNIQUE ("student_id", "job_id"),
        CONSTRAINT "FK_saved_jobs_student" FOREIGN KEY ("student_id") REFERENCES "student_profiles" ("id") ON DELETE CASCADE,
        CONSTRAINT "FK_saved_jobs_job" FOREIGN KEY ("job_id") REFERENCES "jobs" ("id") ON DELETE CASCADE
      )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "saved_jobs"`);
  }
}
