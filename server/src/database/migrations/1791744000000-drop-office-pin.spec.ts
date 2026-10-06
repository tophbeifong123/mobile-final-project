import { type QueryRunner } from 'typeorm';
import { DropOfficePin1791744000000 } from './1791744000000-drop-office-pin.js';

describe('DropOfficePin1791744000000', () => {
  it('drops unused office coordinates and can restore the previous columns', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new DropOfficePin1791744000000();

    await migration.up(runner);

    const statements = query.mock.calls.map(([sql]: [string]) => sql);
    expect(statements).toContain(
      'ALTER TABLE "company_profiles" DROP COLUMN "latitude"',
    );
    expect(statements).toContain(
      'ALTER TABLE "company_profiles" DROP COLUMN "longitude"',
    );
    expect(statements).toContain(
      'ALTER TABLE "provinces" DROP COLUMN "center_latitude"',
    );
    expect(statements).toContain(
      'ALTER TABLE "provinces" DROP COLUMN "center_longitude"',
    );

    query.mockClear();
    await migration.down(runner);
    const downStatements = query.mock.calls.map(([sql]: [string]) => sql);
    expect(
      downStatements.filter((sql) => sql.includes('UPDATE "provinces"')),
    ).toHaveLength(77);
    expect(downStatements).toContain(
      'ALTER TABLE "company_profiles" ADD "latitude" double precision',
    );
    expect(downStatements).toContain(
      'ALTER TABLE "company_profiles" ADD "longitude" double precision',
    );
  });
});
