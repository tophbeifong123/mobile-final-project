import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class CreateNotificationsTable1758900000000
  implements MigrationInterface
{
  name = 'CreateNotificationsTable1758900000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "notifications" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "student_id" uuid NOT NULL,
        "application_id" uuid NOT NULL,
        "message" varchar(500) NOT NULL,
        "read_at" timestamptz,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "FK_notifications_student" FOREIGN KEY ("student_id") REFERENCES "student_profiles" ("id") ON DELETE CASCADE,
        CONSTRAINT "FK_notifications_application" FOREIGN KEY ("application_id") REFERENCES "applications" ("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_notifications_student_created" ON "notifications" ("student_id", "created_at" DESC)
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "notifications"`);
  }
}
