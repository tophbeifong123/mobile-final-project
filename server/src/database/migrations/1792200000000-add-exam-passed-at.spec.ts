import { type QueryRunner } from 'typeorm';
import { AddExamPassedAt1792200000000 } from './1792200000000-add-exam-passed-at.js';

describe('AddExamPassedAt1792200000000', () => {
  it('records when the company marks the exam passed', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new AddExamPassedAt1792200000000();

    await migration.up(runner);
    expect(query.mock.calls[0][0]).toContain('"exam_passed_at"');
    expect(query.mock.calls[1][0]).toContain(
      'applications_exam_passed_requires_completed',
    );

    await migration.down(runner);
    expect(query.mock.calls[2][0]).toContain('DROP COLUMN "exam_passed_at"');
  });
});
