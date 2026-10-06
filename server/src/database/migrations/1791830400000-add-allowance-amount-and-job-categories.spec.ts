import { type QueryRunner } from 'typeorm';
import { AddAllowanceAmountAndJobCategories1791830400000 } from './1791830400000-add-allowance-amount-and-job-categories.js';

describe('AddAllowanceAmountAndJobCategories1791830400000', () => {
  it('maps categories, requires a known category, and stores an optional allowance amount', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new AddAllowanceAmountAndJobCategories1791830400000();

    await migration.up(runner);
    const statements = query.mock.calls.map(([sql]: [string]) => sql).join('\n');
    expect(statements).toContain('Design & UX/UI');
    expect(statements).toContain('CHK_jobs_category');
    expect(statements).toContain('ADD "allowance_amount" integer');
    expect(statements).toContain('CHK_jobs_allowance_amount');

    query.mockClear();
    await migration.down(runner);
    const down = query.mock.calls.map(([sql]: [string]) => sql).join('\n');
    expect(down).toContain('DROP CONSTRAINT "CHK_jobs_allowance_amount"');
    expect(down).toContain('DROP COLUMN "allowance_amount"');
    expect(down).toContain('DROP CONSTRAINT "CHK_jobs_category"');
  });
});
