import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import test from 'node:test';
import { Client } from 'pg';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

// Use a dedicated local PostgreSQL instance. This test creates and removes only
// its own uniquely named database; it never migrates an existing application DB.
test('company office migration, API and canonical province filtering', async () => {
  const port = Number(process.env.OFFICE_INTEGRATION_PORT);
  assert.ok(
    Number.isInteger(port) && port > 0 && port !== 5432,
    'Set OFFICE_INTEGRATION_PORT to a dedicated local test PostgreSQL port',
  );
  const database = `ifnd138_test_${randomUUID().replaceAll('-', '')}`;
  assert.match(database, /^ifnd138_test_[a-f0-9]{32}$/);
  const admin = new Client({
    host: '127.0.0.1',
    port,
    user: 'postgres',
    password: '',
    database: 'postgres',
  });
  await admin.connect();
  let source;
  let app;
  let created = false;
  try {
    await admin.query(`CREATE DATABASE "${database}"`);
    created = true;
    Object.assign(process.env, {
      DATABASE_HOST: '127.0.0.1',
      DATABASE_PORT: String(port),
      DATABASE_USER: 'postgres',
      DATABASE_PASSWORD: '',
      DATABASE_NAME: database,
      JWT_SECRET: 'local-integration-test-only-secret',
      NODE_ENV: 'test',
    });
    const { AppDataSource } = await import('../dist/database/data-source.js');
    source = await AppDataSource.initialize();
    await source.runMigrations();
    const [{ count }] = await source.query(
      'SELECT count(*)::int AS count FROM provinces',
    );
    assert.equal(count, 77);

    await source.undoLastMigration();
    const [{ table }] = await source.query(
      "SELECT to_regclass('public.provinces') AS table",
    );
    assert.equal(table, null);
    const columns = await source.query(
      "SELECT column_name FROM information_schema.columns WHERE table_name = 'company_profiles'",
    );
    assert.ok(columns.some((item) => item.column_name === 'location'));
    for (const column of ['province_id', 'latitude', 'longitude']) {
      assert.ok(!columns.some((item) => item.column_name === column));
    }

    const legacyUserId = randomUUID();
    const legacyCompanyId = randomUUID();
    const legacyJobId = randomUUID();
    const prefixedLegacyJobId = randomUUID();
    await source.query(
      'INSERT INTO users (id,email,password_hash,role) VALUES ($1,$2,$3,$4)',
      [legacyUserId, 'legacy@example.test', 'unused-test-hash', 'company'],
    );
    await source.query(
      'INSERT INTO company_profiles (id,user_id,name,location) VALUES ($1,$2,$3,$4)',
      [legacyCompanyId, legacyUserId, 'Legacy company', 'legacy address '.repeat(30)],
    );
    await source.query(
      `INSERT INTO jobs
      (id,company_id,title,description,province,work_mode,category,has_allowance,requirements)
      VALUES ($1,$2,'Legacy internship','Test','กรุงเทพฯ','on_site','IT',false,'Test')`,
      [legacyJobId, legacyCompanyId],
    );
    await source.query(
      `INSERT INTO jobs
      (id,company_id,title,description,province,work_mode,category,has_allowance,requirements)
      VALUES ($1,$2,'Prefixed legacy internship','Test','จังหวัด กทม.','on_site','IT',false,'Test')`,
      [prefixedLegacyJobId, legacyCompanyId],
    );
    await source.runMigrations();
    const [legacyProfile] = await source.query(
      'SELECT location FROM company_profiles WHERE id=$1', [legacyCompanyId],
    );
    assert.equal(legacyProfile.location, 'legacy address '.repeat(30));
    await source.undoLastMigration();
    const [afterRollback] = await source.query(
      'SELECT location FROM company_profiles WHERE id=$1', [legacyCompanyId],
    );
    assert.equal(afterRollback.location, legacyProfile.location);
    await source.runMigrations();
    const [legacyJob] = await source.query(
      'SELECT province FROM jobs WHERE id=$1',
      [legacyJobId],
    );
    assert.equal(legacyJob.province, 'กรุงเทพมหานคร');
    const [prefixedLegacyJob] = await source.query(
      'SELECT province FROM jobs WHERE id=$1',
      [prefixedLegacyJobId],
    );
    assert.equal(prefixedLegacyJob.province, 'กรุงเทพมหานคร');
    await assert.rejects(
      source.query(
        'UPDATE company_profiles SET latitude=7,longitude=100 WHERE id=$1',
        [legacyCompanyId],
      ),
      (error) => error.driverError?.code === '23514',
    );

    const { AppModule } = await import('../dist/app.module.js');
    app = await NestFactory.create(AppModule, {
      logger: false,
      abortOnError: false,
    });
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.listen(0, '127.0.0.1');
    const origin = await app.getUrl();
    const request = async (path, { method = 'GET', token, body } = {}) => {
      const response = await fetch(`${origin}/api${path}`, {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        ...(body === undefined ? {} : { body: JSON.stringify(body) }),
      });
      return { status: response.status, body: await response.json() };
    };

    const provinces = await request('/provinces');
    assert.equal(provinces.status, 200);
    assert.equal(provinces.body.length, 77);
    assert.equal(
      provinces.body.find((province) => province.id === 10).nameTh,
      'กรุงเทพมหานคร',
    );
    assert.ok(
      provinces.body
        .find((province) => province.id === 10)
        .aliases.includes('กทม.'),
    );
    const register = async (role) => {
      const response = await request('/auth/register', {
        method: 'POST',
        body: {
          email: `${role}-${randomUUID()}@example.test`,
          password: 'Test-password-123',
          role,
        },
      });
      assert.equal(response.status, 201);
      assert.ok(response.body.accessToken);
      return response.body.accessToken;
    };
    const companyToken = await register('company');
    const studentToken = await register('student');
    const patch = (body) =>
      request('/companies/me', { method: 'PATCH', token: companyToken, body });
    assert.equal((await patch({ latitude: 7, longitude: 100 })).status, 400);
    assert.equal((await patch({ provinceId: 90, latitude: 7 })).status, 400);
    assert.equal((await patch({ provinceId: 999 })).status, 400);
    assert.equal(
      (await patch({ provinceId: 90, latitude: 91, longitude: 100 })).status,
      400,
    );
    const saved = await patch({
      name: 'Office test',
      businessType: 'IT',
      provinceId: 90,
      location: ' อาคาร A ถนนกาญจนวนิช ',
      latitude: 7.0064,
      longitude: 100.5008,
    });
    assert.equal(saved.status, 200);
    assert.equal(saved.body.provinceName, 'สงขลา');
    assert.equal(saved.body.location, 'อาคาร A ถนนกาญจนวนิช');
    assert.equal(saved.body.latitude, 7.0064);
    assert.equal(
      (await request('/companies/me', { token: companyToken })).body.longitude,
      100.5008,
    );
    const moved = await patch({ provinceId: 10 });
    assert.equal(moved.status, 200);
    assert.equal(moved.body.provinceName, 'กรุงเทพมหานคร');
    assert.equal(moved.body.latitude, null);
    assert.equal(moved.body.longitude, null);
    assert.equal(
      (await patch({ latitude: 13.7563, longitude: 100.5018 })).status,
      200,
    );
    const cleared = await patch({ provinceId: null });
    assert.equal(cleared.status, 200);
    assert.equal(cleared.body.latitude, null);
    assert.equal(cleared.body.longitude, null);
    assert.equal(
      (
        await request('/companies/me', {
          method: 'PATCH',
          token: studentToken,
          body: { provinceId: 10 },
        })
      ).status,
      403,
    );

    const job = await request('/company/jobs', {
      method: 'POST',
      token: companyToken,
      body: {
        title: 'Province test internship',
        description: 'Test',
        province: 'กทม.',
        workMode: 'on_site',
        category: 'IT',
        hasAllowance: false,
        requirements: 'Test',
      },
    });
    assert.equal(job.status, 201);
    assert.equal(job.body.province, 'กรุงเทพมหานคร');
    for (const province of ['กรุงเทพมหานคร', 'กรุงเทพฯ', 'จังหวัด กทม.']) {
      const feed = await request(
        `/jobs?province=${encodeURIComponent(province)}`,
        { token: studentToken },
      );
      assert.equal(feed.status, 200);
      assert.ok(feed.body.items.some((item) => item.id === job.body.id));
      assert.ok(feed.body.items.some((item) => item.id === legacyJobId));
      assert.ok(
        feed.body.items.some((item) => item.id === prefixedLegacyJobId),
      );
    }
    const otherProvince = await request(
      `/jobs?province=${encodeURIComponent('สงขลา')}`,
      { token: studentToken },
    );
    assert.equal(otherProvince.body.items.length, 0);

    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder()
        .setTitle('InternFinder API')
        .addBearerAuth()
        .build(),
    );
    assert.ok(document.paths['/api/provinces'].get);
    assert.ok(!document.paths['/api/provinces'].get.security?.length);
    for (const property of [
      'provinceId',
      'provinceName',
      'location',
      'latitude',
      'longitude',
    ]) {
      assert.ok(
        document.components.schemas.CompanyProfileDto.properties[property],
      );
    }
    const profileSchema =
      document.components.schemas.CompanyProfileDto.properties;
    const updateSchema =
      document.components.schemas.UpdateCompanyProfileDto.properties;
    assert.equal(profileSchema.provinceId.type, 'integer');
    assert.equal(profileSchema.provinceName.type, 'string');
    for (const property of ['latitude', 'longitude']) {
      assert.equal(profileSchema[property].type, 'number');
      assert.equal(updateSchema[property].type, 'number');
      assert.equal(updateSchema[property].nullable, true);
    }
    assert.equal(updateSchema.provinceId.type, 'integer');
  } finally {
    if (app) await app.close();
    if (source?.isInitialized) await source.destroy();
    if (created) await admin.query(`DROP DATABASE "${database}" WITH (FORCE)`);
    await admin.end();
  }
});
