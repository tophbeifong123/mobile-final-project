import { type QueryRunner } from 'typeorm';
import { AddJobInterviewMode1792100000000 } from './1792100000000-add-job-interview-mode.js';

describe('AddJobInterviewMode1792100000000', () => {
  it('adds the interview mode and lets an on-site appointment omit a link', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new AddJobInterviewMode1792100000000();

    await migration.up(runner);
    const up = query.mock.calls.map((call) => String(call[0])).join('\n');
    expect(up).toContain(`CREATE TYPE "interview_mode"`);
    expect(up).toContain(`WHEN "work_mode" = 'on_site'`);
    expect(up).toContain(`OR "interview_starts_at" IS NOT NULL`);

    await migration.down(runner);
    const down = query.mock.calls
      .slice(5)
      .map((call) => String(call[0]))
      .join('\n');
    expect(down).toContain('DROP TYPE "interview_mode"');
    expect(down).toContain(
      `("interview_url" IS NOT NULL AND "interview_starts_at" IS NOT NULL)`,
    );
  });
});
