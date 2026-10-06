import { type MigrationInterface, type QueryRunner } from 'typeorm';
import { PROVINCE_SEEDS } from './province-seed-1791158400000.js';

export class DropOfficePin1791744000000 implements MigrationInterface {
  name = 'DropOfficePin1791744000000';

  async up(queryRunner: QueryRunner): Promise<void> {
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
      `ALTER TABLE "company_profiles" DROP COLUMN "longitude"`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" DROP COLUMN "latitude"`,
    );
    await queryRunner.query(
      `ALTER TABLE "provinces" DROP COLUMN "center_longitude"`,
    );
    await queryRunner.query(
      `ALTER TABLE "provinces" DROP COLUMN "center_latitude"`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "provinces" ADD "center_latitude" double precision`,
    );
    await queryRunner.query(
      `ALTER TABLE "provinces" ADD "center_longitude" double precision`,
    );
    for (const province of PROVINCE_SEEDS) {
      await queryRunner.query(
        `UPDATE "provinces" SET "center_latitude" = $2, "center_longitude" = $3 WHERE "id" = $1`,
        [province.id, province.centerLatitude, province.centerLongitude],
      );
    }
    await queryRunner.query(
      `ALTER TABLE "provinces" ALTER COLUMN "center_latitude" SET NOT NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "provinces" ALTER COLUMN "center_longitude" SET NOT NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD "latitude" double precision`,
    );
    await queryRunner.query(
      `ALTER TABLE "company_profiles" ADD "longitude" double precision`,
    );
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
  }
}
