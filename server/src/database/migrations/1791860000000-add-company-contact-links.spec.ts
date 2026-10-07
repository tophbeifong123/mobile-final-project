import { type QueryRunner } from 'typeorm';
import { AddCompanyContactLinks1791860000000 } from './1791860000000-add-company-contact-links.js';

describe('AddCompanyContactLinks1791860000000', () => {
  it('adds company contact links and can remove them', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new AddCompanyContactLinks1791860000000();

    await migration.up(runner);
    expect(query).toHaveBeenCalledWith(
      `ALTER TABLE "company_profiles" ADD COLUMN IF NOT EXISTS "contact_links" jsonb NOT NULL DEFAULT '[]'::jsonb`,
    );

    query.mockClear();
    await migration.down(runner);
    expect(query).toHaveBeenCalledWith(
      `ALTER TABLE "company_profiles" DROP COLUMN IF EXISTS "contact_links"`,
    );
  });
});
