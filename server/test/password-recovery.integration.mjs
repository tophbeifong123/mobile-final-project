import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { createServer } from 'node:net';
import test from 'node:test';

// Run after npm run build + migration:run, using a local/disposable PostgreSQL.
// SMTP is always captured on loopback; this test never sends real email.
test('password recovery across API, SMTP and PostgreSQL', { timeout: 60_000 }, async () => {
  const messages = [];
  const smtp = createServer((socket) => {
    socket.setEncoding('utf8');
    socket.write('220 local-test SMTP ready\r\n');
    let buffer = '';
    let data = null;
    socket.on('data', (chunk) => {
      buffer += chunk;
      let end;
      while ((end = buffer.indexOf('\r\n')) >= 0) {
        const line = buffer.slice(0, end);
        buffer = buffer.slice(end + 2);
        if (data !== null) {
          if (line === '.') {
            messages.push(data);
            data = null;
            socket.write('250 queued\r\n');
          } else {
            data += `${line}\r\n`;
          }
        } else if (/^(EHLO|HELO) /i.test(line)) {
          socket.write('250-local-test\r\n250 8BITMIME\r\n');
        } else if (/^DATA$/i.test(line)) {
          data = '';
          socket.write('354 end with a dot\r\n');
        } else if (/^QUIT$/i.test(line)) {
          socket.end('221 bye\r\n');
        } else {
          socket.write('250 OK\r\n');
        }
      }
    });
  });
  await new Promise((resolve) => smtp.listen(0, '127.0.0.1', resolve));
  Object.assign(process.env, {
    SMTP_HOST: '127.0.0.1', SMTP_PORT: String(smtp.address().port),
    SMTP_SECURE: 'false', SMTP_REQUIRE_TLS: 'false',
    SMTP_USER: '', SMTP_PASSWORD: '', SMTP_FROM: 'InternFinder <test@example.com>',
    APP_WEB_URL: 'http://127.0.0.1:8085', NODE_ENV: 'test',
  });
  const { NestFactory } = await import('@nestjs/core');
  const { SwaggerModule, DocumentBuilder } = await import('@nestjs/swagger');
  const { configureApp } = await import('../dist/configure-app.js');
  // Compiled imports retain TypeScript constructor metadata used by Nest.
  const { AppModule } = await import('../dist/app.module.js');
  const { AuthRepository } = await import('../dist/auth/auth.repository.js');
  const { DataSource } = await import('typeorm');
  const { AddPasswordRecovery1791072000000 } = await import('../dist/database/migrations/1791072000000-add-password-recovery.js');
  const app = await NestFactory.create(AppModule, { logger: false });
  configureApp(app);
  await app.listen(0, '127.0.0.1');
  const page = await fetch(`${await app.getUrl()}/reset-password?token=not-in-the-page`);
  assert.equal(page.status, 200);
  const html = await page.text();
  assert.match(html, /ตั้งรหัสผ่านใหม่/);
  assert.equal(html.includes('not-in-the-page'), false);
  assert.match(page.headers.get('content-security-policy') ?? '', /script-src 'nonce-/);
  assert.equal(page.headers.get('referrer-policy'), 'no-referrer');
  assert.equal((await fetch(`${await app.getUrl()}/api/reset-password`)).status, 404);
  const swagger = SwaggerModule.createDocument(app, new DocumentBuilder().setTitle('InternFinder API').setVersion('1.0').build());
  const forgotSchema = swagger.components.schemas.ForgotPasswordDto.properties.email;
  assert.equal(forgotSchema.format, 'email');
  assert.equal(forgotSchema.pattern, undefined, 'Swagger has no domain allowlist pattern');
  assert.doesNotMatch(JSON.stringify([
    swagger.paths['/api/auth/forgot-password'],
    swagger.paths['/api/auth/reset-password'],
    forgotSchema,
  ]), /psu/i, 'Swagger does not describe a PSU-only recovery policy');
  assert.equal(swagger.paths['/reset-password'], undefined, 'the HTML reset page is not an API route');
  const origin = await app.getUrl();
  const db = app.get(DataSource);
  const repository = app.get(AuthRepository);
  const id = randomUUID();
  const email = `recovery-${id}@gmail.com`;
  const companyEmail = `recovery-company-${id}@outlook.com`;
  const externalEmail = `recovery-external-${id}@example.com`;
  const post = async (path, body) => {
    const response = await fetch(`${origin}/api/auth/${path}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
    });
    return { status: response.status, body: await response.json(), headers: response.headers };
  };
  const assertStatus = (response, status) => assert.equal(response.status, status, JSON.stringify(response.body));
  const decodeMail = (message) => {
    const separator = message.indexOf('\r\n\r\n');
    const headers = message.slice(0, separator);
    const body = message.slice(separator + 4);
    const decoded = /Content-Transfer-Encoding: base64/i.test(headers)
      ? Buffer.from(body.replace(/\s/g, ''), 'base64').toString('utf8')
      : body.replace(/=\r\n/g, '').replace(/=([A-Fa-f0-9]{2})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)));
    return `${headers}\r\n\r\n${decoded}`;
  };
  const waitForMail = async (recipient, excludeToken) => {
    const findMail = () => messages.map(decodeMail).find((message) =>
      message.includes(`To: ${recipient}\r\n`) && /token=[a-f0-9]{64}/.test(message) && (!excludeToken || !message.includes(excludeToken)));
    for (let attempt = 0; attempt < 100 && !findMail(); attempt++) {
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    const message = findMail();
    assert.ok(message, `SMTP message was delivered to the registered address: ${recipient}`);
    return message;
  };
  try {
    assertStatus(await post('register', { email: externalEmail, password: 'external-password-123', role: 'student' }), 201);
    assertStatus(await post('forgot-password', { email: 'student@@example.com' }), 400);
    const unknownOutlook = await post('forgot-password', { email: `unknown-${id}@outlook.com` });
    assertStatus(unknownOutlook, 200);
    const session = await post('register', { email, password: 'original-password-123', role: 'student' });
    assertStatus(session, 201);
    const unknown = await post('forgot-password', { email: `unknown-${id}@email.psu.ac.th` });
    assertStatus(unknown, 200);
    assert.equal(messages.length, 0, 'unknown account receives no email');
    const known = await post('forgot-password', { email: `  ${email.toUpperCase()}  ` });
    assertStatus(known, 200);
    assert.ok(known.headers.get('access-control-expose-headers')?.includes('Retry-After'), 'Flutter web can read rate-limit wait time');
    assert.deepEqual(known.body, unknown.body, 'no account enumeration or token disclosure');
    assert.deepEqual(known.body, unknownOutlook.body, 'response is identical across email providers');
    const resetEmail = await waitForMail(email);
    let token = /token=([a-f0-9]{64})/.exec(resetEmail)?.[1];
    assert.ok(token, 'email contains a 256-bit URL token');
    assert.ok(resetEmail.includes('http://127.0.0.1:8085/reset-password#token='));
    const stored = await db.query('SELECT token_hash, expires_at FROM password_reset_tokens p JOIN users u ON u.id = p.user_id WHERE u.email = $1', [email]);
    assert.equal(stored.length, 1);
    assert.notEqual(stored[0].token_hash, token, 'only the hash is stored');
    assert.equal(stored[0].token_hash, createHash('sha256').update(token).digest('hex'));
    assert.ok(stored[0].expires_at.getTime() > Date.now() + 14 * 60_000);
    assertStatus(await post('forgot-password', { email }), 200);
    assert.equal(messages.length, 1, 'per-account cooldown blocks repeated mail');
    // Advance only this test account's issue time, avoiding a one-minute sleep.
    await db.query(`UPDATE password_reset_tokens p SET created_at = now() - interval '2 minutes' FROM users u WHERE p.user_id = u.id AND u.email = $1`, [email]);
    assertStatus(await post('forgot-password', { email }), 200);
    const replacementMail = await waitForMail(email, token);
    const replacementToken = /token=([a-f0-9]{64})/.exec(replacementMail)?.[1];
    assert.ok(replacementToken && replacementToken !== token);
    assertStatus(await post('reset-password', { token, password: 'not-used-password' }), 400);
    token = replacementToken;
    assertStatus(await post('reset-password', { token, password: 'short' }), 400);
    assertStatus(await post('reset-password', { token: '0'.repeat(64), password: 'new-password-123' }), 400);
    const reused = await post('reset-password', { token, password: 'original-password-123' });
    assertStatus(reused, 409);
    assert.equal(reused.body.code, 'PASSWORD_REUSE');
    const afterReuse = await db.query('SELECT token_hash FROM password_reset_tokens p JOIN users u ON u.id = p.user_id WHERE u.email = $1', [email]);
    assert.equal(afterReuse[0]?.token_hash, createHash('sha256').update(token).digest('hex'), 'the reset link remains usable after trying the existing password');
    const resets = await Promise.all([
      post('reset-password', { token, password: 'new-password-123' }),
      post('reset-password', { token, password: 'other-password-123' }),
    ]);
    assert.deepEqual(resets.map((response) => response.status).sort(), [200, 400], 'concurrent reset is single-use');
    const password = resets[0].status === 200 ? 'new-password-123' : 'other-password-123';
    assertStatus(await post('reset-password', { token, password }), 400);
    assertStatus(await post('login', { email, password: 'original-password-123' }), 401);
    assertStatus(await post('login', { email, password }), 200);
    assertStatus(await post('refresh', { refreshToken: session.body.refreshToken }), 401);
    const oldAccess = await fetch(`${origin}/api/students/me`, { headers: { Authorization: `Bearer ${session.body.accessToken}` } });
    assert.equal(oldAccess.status, 401, 'old access JWT is invalidated immediately');
    const user = await repository.findByEmail(email);
    assert.equal(user.tokenVersion, 1);
    assert.equal(await repository.saveRefreshToken({ userId: user.id, tokenHash: randomUUID(), expiresAt: new Date(Date.now() + 60_000), tokenVersion: 0 }), false, 'login issued before reset cannot open a later session');
    // An expired token is rejected without changing a usable password.
    const expiredHash = createHash('sha256').update('f'.repeat(64)).digest('hex');
    await db.query(`INSERT INTO password_reset_tokens (user_id, token_hash, expires_at, created_at) VALUES ($1, $2, now() - interval '1 minute', now() - interval '2 minutes')`, [user.id, expiredHash]);
    assertStatus(await post('reset-password', { token: 'f'.repeat(64), password: 'never-used-password' }), 400);
    // Company recovery follows exactly the same flow.
    const companySession = await post('register', { email: companyEmail, password: 'company-password-123', role: 'company' });
    assertStatus(companySession, 201);
    assertStatus(await post('forgot-password', { email: companyEmail }), 200);
    const companyMail = await waitForMail(companyEmail);
    const companyToken = /token=([a-f0-9]{64})/.exec(companyMail)?.[1];
    assert.ok(companyToken);
    assertStatus(await post('reset-password', { token: companyToken, password: 'new-company-password' }), 200);
    const companyLogin = await post('login', { email: companyEmail, password: 'new-company-password' });
    assertStatus(companyLogin, 200);
    assert.equal(companyLogin.body.role, 'company');
    assertStatus(await post('login', { email: companyEmail, password: 'company-password-123' }), 401);
    assertStatus(await post('refresh', { refreshToken: companySession.body.refreshToken }), 401);
    const oldCompanyAccess = await fetch(`${origin}/api/companies/me`, { headers: { Authorization: `Bearer ${companySession.body.accessToken}` } });
    assert.equal(oldCompanyAccess.status, 401, 'company sessions are invalidated as well');
    // Still-valid links for other domains are no longer blocked in the service or transaction.
    const externalUser = await repository.findByEmail(externalEmail);
    const legacyToken = 'd'.repeat(64);
    const legacyHash = createHash('sha256').update(legacyToken).digest('hex');
    assert.equal(await repository.replacePasswordResetToken({ userId: externalUser.id, tokenHash: legacyHash, expiresAt: new Date(Date.now() + 10 * 60_000) }), true);
    assertStatus(await post('reset-password', { token: legacyToken, password: 'new-external-password' }), 200);
    assertStatus(await post('login', { email: externalEmail, password: 'external-password-123' }), 401);
    assertStatus(await post('login', { email: externalEmail, password: 'new-external-password' }), 200);
    let limited;
    for (let attempt = 0; attempt < 11; attempt++) {
      limited = await post('forgot-password', { email: `unknown-${id}@email.psu.ac.th` });
      if (limited.status === 429) break;
    }
    assertStatus(limited, 429);
    assert.ok(Number(limited.headers.get('retry-after')) > 0);
    // Migration down/up is exercised only in a fresh schema transaction, then rolled back.
    const runner = db.createQueryRunner();
    await runner.connect();
    await runner.startTransaction();
    try {
      const migration = new AddPasswordRecovery1791072000000();
      await migration.down(runner);
      await migration.up(runner);
    } finally {
      await runner.rollbackTransaction();
      await runner.release();
    }
  } finally {
    // Delete only the three uniquely named accounts created by this test.
    await db.query('DELETE FROM users WHERE email IN ($1, $2, $3)', [email, companyEmail, externalEmail]);
    await app.close();
    await new Promise((resolve) => smtp.close(resolve));
  }
});
