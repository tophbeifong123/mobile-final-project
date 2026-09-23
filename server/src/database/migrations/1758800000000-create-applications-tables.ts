import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class CreateApplicationsTables1758800000000
  implements MigrationInterface
{
  name = 'CreateApplicationsTables1758800000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE "application_status" AS ENUM ('submitted', 'reviewing', 'accepted', 'rejected')
    `);

    await queryRunner.query(`
      CREATE TABLE "applications" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "student_id" uuid NOT NULL,
        "job_id" uuid NOT NULL,
        "cover_letter" text NOT NULL,
        "resume_object_key" varchar(1024) NOT NULL,
        "status" "application_status" NOT NULL DEFAULT 'submitted',
        "version" int NOT NULL DEFAULT 1,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_applications_student_job" UNIQUE ("student_id", "job_id"),
        CONSTRAINT "FK_applications_student" FOREIGN KEY ("student_id") REFERENCES "student_profiles" ("id") ON DELETE CASCADE,
        CONSTRAINT "FK_applications_job" FOREIGN KEY ("job_id") REFERENCES "jobs" ("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_applications_job_id" ON "applications" ("job_id")
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_applications_student_id" ON "applications" ("student_id")
    `);

    await queryRunner.query(`
      CREATE TABLE "application_status_events" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "application_id" uuid NOT NULL,
        "from_status" "application_status",
        "to_status" "application_status" NOT NULL,
        "actor_user_id" uuid NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "FK_events_application" FOREIGN KEY ("application_id") REFERENCES "applications" ("id") ON DELETE CASCADE,
        CONSTRAINT "FK_events_actor" FOREIGN KEY ("actor_user_id") REFERENCES "users" ("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_events_application_id" ON "application_status_events" ("application_id")
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "application_status_events"`);
    await queryRunner.query(`DROP TABLE "applications"`);
    await queryRunner.query(`DROP TYPE "application_status"`);
  }
}
