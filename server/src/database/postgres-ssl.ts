import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const rootCertificates = [
  'DigiCertGlobalRootCA.crt.pem',
  'DigiCertGlobalRootG2.crt.pem',
];

export function postgresSslConfig():
  | { ca: string; rejectUnauthorized: true }
  | undefined {
  if (process.env.DATABASE_SSL !== 'true') {
    return undefined;
  }

  const certDir = join(dirname(fileURLToPath(import.meta.url)), '../../certs');
  const ca = rootCertificates
    .map((name) => readFileSync(join(certDir, name), 'utf8'))
    .join('\n');
  return { ca, rejectUnauthorized: true };
}
