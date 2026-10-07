import { postgresSslConfig } from './postgres-ssl.js';

describe('postgresSslConfig', () => {
  const original = process.env.DATABASE_SSL;

  afterEach(() => {
    if (original === undefined) {
      delete process.env.DATABASE_SSL;
    } else {
      process.env.DATABASE_SSL = original;
    }
  });

  it('stays off unless DATABASE_SSL is true', () => {
    delete process.env.DATABASE_SSL;
    expect(postgresSslConfig()).toBeUndefined();
  });

  it('trusts the DigiCert roots when SSL is required', () => {
    process.env.DATABASE_SSL = 'true';
    const ssl = postgresSslConfig();
    expect(ssl?.rejectUnauthorized).toBe(true);
    expect(ssl?.ca).toContain('BEGIN CERTIFICATE');
    expect(ssl?.ca.match(/BEGIN CERTIFICATE/g)).toHaveLength(2);
  });
});
