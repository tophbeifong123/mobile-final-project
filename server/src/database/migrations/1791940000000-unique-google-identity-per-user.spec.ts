import { type QueryRunner } from 'typeorm';
import { UniqueGoogleIdentityPerUser1791940000000 } from './1791940000000-unique-google-identity-per-user.js';

describe('UniqueGoogleIdentityPerUser1791940000000', () => {
  it('allows one provider identity per user and can drop that constraint', async () => {
    const query = vi.fn().mockResolvedValue(undefined);
    const runner = { query } as unknown as QueryRunner;
    const migration = new UniqueGoogleIdentityPerUser1791940000000();

    await migration.up(runner);
    expect(query.mock.calls[0][0]).toContain(
      'UQ_auth_identities_user_provider',
    );
    expect(query.mock.calls[0][0]).toContain('"user_id", "provider"');

    await migration.down(runner);
    expect(query.mock.calls[1][0]).toContain(
      'DROP INDEX "UQ_auth_identities_user_provider"',
    );
  });
});
