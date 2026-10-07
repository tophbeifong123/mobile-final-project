import { createHash } from 'node:crypto';
import { MigrationInterface, QueryRunner } from 'typeorm';

const MAJORS = [
  'วิศวกรรมคอมพิวเตอร์',
  'วิศวกรรมซอฟต์แวร์',
  'วิทยาการคอมพิวเตอร์',
  'เทคโนโลยีสารสนเทศ',
  'วิศวกรรมไฟฟ้า',
  'วิศวกรรมเครื่องกล',
  'วิศวกรรมโยธา',
  'วิศวกรรมอุตสาหการ',
  'วิศวกรรมเคมี',
  'วิศวกรรมสิ่งแวดล้อม',
  'วิศวกรรมชีวการแพทย์',
  'วิทยาการข้อมูล',
  'ปัญญาประดิษฐ์',
  'ความมั่นคงปลอดภัยไซเบอร์',
  'บัญชี',
  'การเงิน',
  'การตลาด',
  'บริหารธุรกิจ',
  'การจัดการ',
  'โลจิสติกส์',
  'เศรษฐศาสตร์',
  'นิเทศศาสตร์',
  'ออกแบบกราฟิก',
  'ออกแบบผลิตภัณฑ์',
  'สถาปัตยกรรมศาสตร์',
  'ภาษาอังกฤษ',
  'การท่องเที่ยวและการโรงแรม',
  'รัฐศาสตร์',
  'นิติศาสตร์',
  'จิตวิทยา',
  'สาธารณสุขศาสตร์',
  'พยาบาลศาสตร์',
  'วิทยาศาสตร์ชีวภาพ',
  'เคมี',
  'ฟิสิกส์',
  'คณิตศาสตร์',
];

function majorId(nameTh: string): string {
  const bytes = createHash('sha256')
    .update(`internfinder:major:${nameTh}`)
    .digest()
    .subarray(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

export class AddStudentMajorMaster1791331200000 implements MigrationInterface {
  name = 'AddStudentMajorMaster1791331200000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "majors" (
        "id" uuid NOT NULL,
        "name_th" varchar(255) NOT NULL,
        CONSTRAINT "PK_majors" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_majors_name_th" UNIQUE ("name_th")
      )
    `);
    for (const nameTh of MAJORS) {
      await queryRunner.query(
        'INSERT INTO "majors" ("id", "name_th") VALUES ($1, $2)',
        [majorId(nameTh), nameTh],
      );
    }

    await queryRunner.query('ALTER TABLE "student_profiles" ADD COLUMN "major_id" uuid');
    await queryRunner.query(
      'ALTER TABLE "student_profiles" ADD COLUMN "custom_major_name" varchar(255)',
    );
    await queryRunner.query(`
      ALTER TABLE "student_profiles"
      ADD CONSTRAINT "FK_student_profiles_major"
      FOREIGN KEY ("major_id") REFERENCES "majors" ("id") ON DELETE RESTRICT
    `);
    await queryRunner.query(`
      ALTER TABLE "student_profiles"
      ADD CONSTRAINT "CHK_student_profiles_major_choice"
      CHECK ("major_id" IS NULL OR "custom_major_name" IS NULL)
    `);

    await queryRunner.query(`
      UPDATE "student_profiles" AS profile
      SET "major_id" = (
        SELECT major."id"
        FROM "majors" AS major
        WHERE lower(regexp_replace(major."name_th", '[[:space:]]+', '', 'g')) =
          lower(regexp_replace(btrim(profile."major"), '[[:space:]]+', '', 'g'))
        LIMIT 1
      )
      WHERE btrim(profile."major") <> ''
        AND (
          SELECT count(*)
          FROM "majors" AS major
          WHERE lower(regexp_replace(major."name_th", '[[:space:]]+', '', 'g')) =
            lower(regexp_replace(btrim(profile."major"), '[[:space:]]+', '', 'g'))
        ) = 1
    `);
    await queryRunner.query(`
      UPDATE "student_profiles"
      SET "custom_major_name" = btrim("major")
      WHERE btrim("major") <> '' AND "major_id" IS NULL
    `);
    await queryRunner.query('CREATE INDEX "IDX_student_profiles_major_id" ON "student_profiles" ("major_id")');
    await queryRunner.query('ALTER TABLE "student_profiles" DROP COLUMN "major"');
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE "student_profiles" ADD COLUMN "major" varchar(255) NOT NULL DEFAULT \'\'',
    );
    await queryRunner.query(`
      UPDATE "student_profiles" AS profile
      SET "major" = COALESCE(profile."custom_major_name", major."name_th", '')
      FROM "majors" AS major
      WHERE profile."major_id" = major."id"
    `);
    await queryRunner.query(`
      UPDATE "student_profiles"
      SET "major" = "custom_major_name"
      WHERE "custom_major_name" IS NOT NULL
    `);
    await queryRunner.query('ALTER TABLE "student_profiles" DROP CONSTRAINT "CHK_student_profiles_major_choice"');
    await queryRunner.query('ALTER TABLE "student_profiles" DROP CONSTRAINT "FK_student_profiles_major"');
    await queryRunner.query('DROP INDEX "IDX_student_profiles_major_id"');
    await queryRunner.query('ALTER TABLE "student_profiles" DROP COLUMN "custom_major_name"');
    await queryRunner.query('ALTER TABLE "student_profiles" DROP COLUMN "major_id"');
    await queryRunner.query('DROP TABLE "majors"');
  }
}
