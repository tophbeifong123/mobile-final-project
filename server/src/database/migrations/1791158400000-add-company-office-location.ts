import { type MigrationInterface, type QueryRunner } from 'typeorm';
import { PROVINCE_SEEDS } from './province-seed-1791158400000.js';

export class AddCompanyOfficeLocation1791158400000 implements MigrationInterface {
  name = 'AddCompanyOfficeLocation1791158400000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "provinces" (
        "id" smallint PRIMARY KEY,
        "name_th" varchar(100) NOT NULL UNIQUE,
        "aliases" text[] NOT NULL DEFAULT '{}',
        "center_latitude" double precision NOT NULL,
        "center_longitude" double precision NOT NULL
      )
    `);

    for (const province of PROVINCE_SEEDS) {
      await queryRunner.query(
        `INSERT INTO "provinces" ("id", "name_th", "aliases", "center_latitude", "center_longitude") VALUES ($1, $2, $3, $4, $5)`,
        [
          province.id,
          province.nameTh,
          province.aliases,
          province.centerLatitude,
          province.centerLongitude,
        ],
      );
    }

    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD "province_id" smallint`,
    );
    // location already belongs to the earlier company-details migration.
    // Keep existing text (including legacy long addresses) on both up and down.
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD "latitude" double precision`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD "longitude" double precision`,
    );
    await queryRunner.query(`
      ALTER TABLE "company_profiles"
      ADD CONSTRAINT "FK_company_profiles_province"
      FOREIGN KEY ("province_id") REFERENCES "provinces" ("id") ON DELETE RESTRICT
    `);
    await queryRunner.query(`
      ALTER TABLE "company_profiles"
      ADD CONSTRAINT "CHK_company_profiles_coordinates_pair"
      CHECK (("latitude" IS NULL AND "longitude" IS NULL)
          OR ("latitude" IS NOT NULL AND "longitude" IS NOT NULL))
    `);
    await queryRunner.query(`
      ALTER TABLE "company_profiles"
      ADD CONSTRAINT "CHK_company_profiles_pin_requires_province"
      CHECK ("latitude" IS NULL OR "province_id" IS NOT NULL)
    `);
    await queryRunner.query(`
      ALTER TABLE "company_profiles"
      ADD CONSTRAINT "CHK_company_profiles_coordinate_ranges"
      CHECK (("latitude" IS NULL OR "latitude" BETWEEN -90 AND 90)
         AND ("longitude" IS NULL OR "longitude" BETWEEN -180 AND 180))
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_company_profiles_province_id" ON "company_profiles" ("province_id")`,
    );

    // Bring existing feed records using colloquial names into the same vocabulary
    // that profiles return. New writes are canonicalized in JobsService.
    await queryRunner.query(`
      UPDATE "jobs" AS job
      SET "province" = province."name_th"
      FROM "provinces" AS province
      WHERE regexp_replace(btrim(job."province"), '^จังหวัด[[:space:]]*', '') = province."name_th"
         OR regexp_replace(btrim(job."province"), '^จังหวัด[[:space:]]*', '') = ANY (province."aliases")
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "IDX_company_profiles_province_id"`);
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP CONSTRAINT "CHK_company_profiles_coordinate_ranges"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP CONSTRAINT "CHK_company_profiles_pin_requires_province"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP CONSTRAINT "CHK_company_profiles_coordinates_pair"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP CONSTRAINT "FK_company_profiles_province"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN "longitude"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN "latitude"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN "province_id"`,
    );
    await queryRunner.query(`DROP TABLE "provinces"`);
  }
}
