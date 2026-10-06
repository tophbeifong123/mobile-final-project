import { type QueryRunner } from 'typeorm';
import { NormalizeAllowanceAmount1791850000000 } from './1791850000000-normalize-allowance-amount.js';

describe('NormalizeAllowanceAmount1791850000000', () => {
  it('stores allowance as whole baht and replaces the looser money check', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new NormalizeAllowanceAmount1791850000000();

    await migration.up(runner);
    const statements = query.mock.calls.map(([sql]: [string]) => sql).join('\n');
    expect(statements).toContain('TYPE integer');
    expect(statements).toContain('DROP CONSTRAINT IF EXISTS "jobs_allowance_amount_valid"');
    expect(statements).toContain('CHK_jobs_allowance_amount');
    expect(statements).toContain('"allowance_amount" <= 1000000');

    query.mockClear();
    await migration.down(runner);
    const down = query.mock.calls.map(([sql]: [string]) => sql).join('\n');
    expect(down).toContain('numeric(10,2)');
    expect(down).toContain('jobs_allowance_amount_valid');
  });
});