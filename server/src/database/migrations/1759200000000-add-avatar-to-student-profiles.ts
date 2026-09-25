import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class AddAvatarToStudentProfiles1759200000000
  implements MigrationInterface
{
  name = 'AddAvatarToStudentProfiles1759200000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "student_profiles" ADD COLUMN IF NOT EXISTS "avatar_object_key" varchar(1024) NULL`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "student_profiles" DROP COLUMN IF EXISTS "avatar_object_key"`,
    );
  }
}
