import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class CreateStudentDocuments1759400000000 implements MigrationInterface {
  name = 'CreateStudentDocuments1759400000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "student_documents" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "student_id" uuid NOT NULL REFERENCES "student_profiles"("id") ON DELETE CASCADE,
        "type" varchar(16) NOT NULL CHECK ("type" IN ('cv', 'transcript', 'other')),
        "object_key" varchar(1024) NOT NULL,
        "file_name" varchar(255) NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now()
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_student_documents_single_type"
      ON "student_documents" ("student_id", "type")
      WHERE "type" IN ('cv', 'transcript')
    `);
    await queryRunner.query(
      'CREATE INDEX "IDX_student_documents_student_id" ON "student_documents" ("student_id")',
    );
    await queryRunner.query(`
      INSERT INTO "student_documents" ("student_id", "type", "object_key", "file_name")
      SELECT "id", 'cv', "resume_object_key", COALESCE("resume_file_name", 'resume.pdf')
      FROM "student_profiles" WHERE "resume_object_key" IS NOT NULL
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    const [{ count }] = await queryRunner.query(`
      SELECT count(*)::int AS count FROM "student_documents"
      WHERE "type" IN ('transcript', 'other')
    `);
    if (count > 0) {
      throw new Error(
        'Cannot revert student documents migration while transcript or other documents exist',
      );
    }
    await queryRunner.query(`
      UPDATE "student_profiles" AS profile
      SET "resume_object_key" = document."object_key",
          "resume_file_name" = document."file_name"
      FROM "student_documents" AS document
      WHERE document."student_id" = profile."id" AND document."type" = 'cv'
    `);
    await queryRunner.query('DROP TABLE "student_documents"');
  }
}
