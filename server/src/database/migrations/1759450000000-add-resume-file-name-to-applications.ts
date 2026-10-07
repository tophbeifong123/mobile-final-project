import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddResumeFileNameToApplications1759450000000
  implements MigrationInterface
{
  name = 'AddResumeFileNameToApplications1759450000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE "applications" ADD COLUMN "resume_file_name" varchar(255)',
    );
    await queryRunner.query(`
      UPDATE "applications" AS application
      SET "resume_file_name" = document."file_name"
      FROM "student_documents" AS document
      WHERE document."student_id" = application."student_id"
        AND document."type" = 'cv'
        AND document."object_key" = application."resume_object_key"
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE "applications" DROP COLUMN "resume_file_name"',
    );
  }
}
