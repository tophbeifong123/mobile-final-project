import { type QueryRunner } from 'typeorm';
import { AddAllowanceAmountAndJobCategories1791830400000 } from './1791830400000-add-allowance-amount-and-job-categories.js';

describe('AddAllowanceAmountAndJobCategories1791830400000', () => {
  it('maps categories onto the shared list and adds an integer allowance column once', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new AddAllowanceAmountAndJobCategories1791830400000();

    await migration.up(runner);
    const statements = query.mock.calls.map(([sql]: [string]) => sql).join('\n');
    expect(statements).toContain('Design & UX/UI');
    expect(statements).toContain('CHK_jobs_category');
    expect(statements).toContain(
      'ADD COLUMN IF NOT EXISTS "allowance_amount" integer',
    );

    query.mockClear();
    await migration.down(runner);
    const down = query.mock.calls.map(([sql]: [string]) => sql).join('\n');
    expect(down).toContain('DROP COLUMN IF EXISTS "allowance_amount"');
    expect(down).toContain('DROP CONSTRAINT IF EXISTS "CHK_jobs_category"');
  });
});
