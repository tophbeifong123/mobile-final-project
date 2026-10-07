import { type QueryRunner } from 'typeorm';
import { AddApplicationSelectionLinks1792000000000 } from './1792000000000-add-application-selection-links.js';

describe('AddApplicationSelectionLinks1792000000000', () => {
  it('adds exam and interview columns as pairs and can drop them', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new AddApplicationSelectionLinks1792000000000();

    await migration.up(runner);
    expect(query.mock.calls[0][0]).toContain('"exam_url"');
    expect(query.mock.calls[0][0]).toContain('"interview_starts_at"');
    expect(query.mock.calls[1][0]).toContain('applications_exam_pair');
    expect(query.mock.calls[1][0]).toContain('applications_interview_pair');

    await migration.down(runner);
    expect(query.mock.calls[2][0]).toContain('DROP COLUMN "exam_url"');
  });
});
