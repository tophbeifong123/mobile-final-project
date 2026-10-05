import { type QueryRunner } from 'typeorm';
import { AddCompanyOfficeLocation1791158400000 } from './1791158400000-add-company-office-location.js';

describe('AddCompanyOfficeLocation1791158400000', () => {
  it('seeds 77 provinces and provides a down migration for the new schema', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new AddCompanyOfficeLocation1791158400000();

    await migration.up(runner);

    const statements = query.mock.calls.map(([sql]: [string]) => sql);
    expect(
      statements.filter((sql) => sql.includes('INSERT INTO "provinces"')),
    ).toHaveLength(77);
    expect(
      statements.some((sql) =>
        sql.includes('ADD CONSTRAINT "FK_company_profiles_province"'),
      ),
    ).toBe(true);
    expect(
      statements.some((sql) =>
        sql.includes('SET "province" = province."name_th"'),
      ),
    ).toBe(true);

    query.mockClear();
    await migration.down(runner);
    const downStatements = query.mock.calls.map(([sql]: [string]) => sql);
    expect(downStatements).toContain('DROP TABLE "provinces"');
    expect(downStatements).toContain(
      'ALTER TABLE "company_profiles" DROP COLUMN "province_id"',
    );
  });
});
