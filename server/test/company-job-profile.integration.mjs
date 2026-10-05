// Run only against a separately started, disposable local PostgreSQL cluster.
import 'reflect-metadata';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { Client } from 'pg';
import { DataSource } from 'typeorm';
import { Test } from '@nestjs/testing';
import { UnauthorizedException, ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import request from 'supertest';
import { AppDataSource } from '../dist/database/data-source.js';
import { CompaniesController } from '../dist/companies/companies.controller.js';
import { CompaniesRepository } from '../dist/companies/companies.repository.js';
import { CompaniesService } from '../dist/companies/companies.service.js';
import { JobsController } from '../dist/jobs/jobs.controller.js';
import { JobsRepository } from '../dist/jobs/jobs.repository.js';
import { JobsService } from '../dist/jobs/jobs.service.js';
import { JwtAuthGuard } from '../dist/auth/jwt-auth.guard.js';
import { StorageService } from '../dist/storage/storage.service.js';
import { ProvincesService } from '../dist/provinces/provinces.service.js';
import { ProvincesRepository } from '../dist/provinces/provinces.repository.js';

test('persisted company profile reaches job detail, logo and Swagger', async () => {
  const port = Number(process.env.COMPANY_PROFILE_INTEGRATION_PORT);
  assert.ok(Number.isInteger(port) && port > 5432 && port < 65536,
    'Set COMPANY_PROFILE_INTEGRATION_PORT to a disposable PostgreSQL port, never production 5432');
  const database = 'ifnd141_test_' + randomUUID().replaceAll('-', '');
  const connection = { host: '127.0.0.1', port, user: 'postgres' };
  const admin = new Client({ ...connection, database: 'postgres' });
  let dataSource;
  let app;
  let created = false;
  await admin.connect();
  try {
    await admin.query('CREATE DATABASE "' + database + '"');
    created = true;
    dataSource = new DataSource({
      ...AppDataSource.options, host: connection.host, port,
      username: connection.user, password: '', database,
      synchronize: false, migrationsRun: false,
    });
    await dataSource.initialize();
    await dataSource.runMigrations();
    const companyUser = randomUUID(), studentUser = randomUUID();
    const companyId = randomUUID(), studentId = randomUUID(), jobId = randomUUID();
    await dataSource.query(
      'INSERT INTO users (id, email, password_hash, role) VALUES ($1, $2, $3, $4), ($5, $6, $3, $7)',
      [companyUser, 'company@fixture.example', 'test-only-hash', 'company',
        studentUser, 'student@fixture.example', 'student'],
    );
    await dataSource.query('INSERT INTO company_profiles (id, user_id, name, business_type, description) VALUES ($1, $2, $3, $4, $5)',
      [companyId, companyUser, 'Initial Company', 'IT', 'Initial description']);
    await dataSource.query('INSERT INTO student_profiles (id, user_id, full_name, university, major) VALUES ($1, $2, $3, $4, $5)',
      [studentId, studentUser, 'Student', 'PSU', 'IT']);
    await dataSource.query('INSERT INTO jobs (id, company_id, title, description, province, work_mode, category, has_allowance, requirements, status) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)',
      [jobId, companyId, 'Flutter Intern', 'Job description', 'สงขลา', 'on_site', 'IT', true, 'Flutter', 'open']);
    const logo = Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10" fill="red"/></svg>');
    const module = await Test.createTestingModule({
      controllers: [CompaniesController, JobsController],
      providers: [
        CompaniesService, JobsService,
        { provide: ProvincesService, useValue: new ProvincesService(new ProvincesRepository(dataSource)) },
        { provide: CompaniesRepository, useValue: new CompaniesRepository(dataSource) },
        { provide: JobsRepository, useValue: new JobsRepository(dataSource) },
        { provide: StorageService, useValue: { get: async key => key === 'company-logos/fixture/logo.svg' ? logo : null } },
      ],
    }).overrideGuard(JwtAuthGuard).useValue({
      canActivate(context) {
        const req = context.switchToHttp().getRequest();
        const role = req.headers['x-test-role'];
        if (role !== 'student' && role !== 'company') throw new UnauthorizedException();
        req.user = { userId: role === 'company' ? companyUser : studentUser, role };
        return true;
      },
    }).compile();
    app = module.createNestApplication({ logger: false });
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    const http = request(app.getHttpServer());
    const fields = {
      name: 'Saved Company', businessType: 'Software', description: 'Saved culture',
      websiteUrl: 'https://example.com/careers', companySize: '201-500',
      perks: ['MacBook', 'Free Lunch'], location: 'อาคาร A ถนนนิพัทธ์อุทิศ',
    };
    const saved = await http.patch('/api/companies/me').set('x-test-role', 'company').send(fields).expect(200);
    const reopened = await http.get('/api/companies/me').set('x-test-role', 'company').expect(200);
    assert.deepEqual(reopened.body, saved.body);
    for (const [key, value] of Object.entries(fields)) assert.deepEqual(reopened.body[key], value);
    const invalid = await http.patch('/api/companies/me').set('x-test-role', 'company')
      .send({ ...fields, name: 'Must not persist', websiteUrl: 'javascript:alert(1)' }).expect(400);
    assert.match(invalid.body.message, /เว็บไซต์/);
    const unchanged = await http.get('/api/companies/me').set('x-test-role', 'company').expect(200);
    assert.equal(unchanged.body.name, fields.name);
    await dataSource.query('UPDATE company_profiles SET logo_object_key = $1 WHERE id = $2',
      ['company-logos/fixture/logo.svg', companyId]);
    const detail = await http.get('/api/jobs/' + jobId).set('x-test-role', 'student').expect(200);
    assert.equal(detail.body.companyName, fields.name);
    assert.equal(detail.body.businessType, fields.businessType);
    assert.equal(detail.body.companyDescription, fields.description);
    assert.equal(detail.body.companyWebsiteUrl, fields.websiteUrl);
    assert.equal(detail.body.companySize, fields.companySize);
    assert.deepEqual(detail.body.companyPerks, fields.perks);
    assert.equal(detail.body.companyLocation, fields.location);
    assert.equal(detail.body.companyLogoAvailable, true);
    assert.ok(!Object.hasOwn(detail.body, 'companyLogoObjectKey'));
    // Subsequent profile edits appear in the job without rewriting the job.
    await http.patch('/api/companies/me').set('x-test-role', 'company').send({ ...fields, websiteUrl: '', perks: [], location: 'อาคาร B' }).expect(200);
    const latest = await http.get('/api/jobs/' + jobId).set('x-test-role', 'student').expect(200);
    assert.equal(latest.body.companyWebsiteUrl, '');
    assert.deepEqual(latest.body.companyPerks, []);
    assert.equal(latest.body.companyLocation, 'อาคาร B');
    const response = await http.get('/api/jobs/' + jobId + '/company-logo').set('x-test-role', 'student').expect(200);
    assert.match(response.headers['content-type'], /image\/svg\+xml/);
    assert.equal(response.headers['x-content-type-options'], 'nosniff');
    assert.equal(response.headers['cache-control'], 'private, no-store');
    assert.equal(response.headers['content-disposition'], 'attachment');
    assert.ok(response.text?.includes('<svg') || response.body.toString().includes('<svg'));
    await http.get('/api/jobs/' + jobId + '/company-logo').set('x-test-role', 'company').expect(403);
    await http.get('/api/jobs/' + jobId + '/company-logo').expect(401);
    await http.get('/api/jobs/not-a-uuid/company-logo').set('x-test-role', 'student').expect(400);
    await dataSource.query("UPDATE jobs SET status = 'closed' WHERE id = $1", [jobId]);
    await http.get('/api/jobs/' + jobId).set('x-test-role', 'student').expect(404);
    await http.get('/api/jobs/' + jobId + '/company-logo').set('x-test-role', 'student').expect(404);
    const doc = SwaggerModule.createDocument(app, new DocumentBuilder().setTitle('Test').addBearerAuth().build());
    assert.ok(doc.paths['/api/jobs/{id}/company-logo'].get);
    for (const field of ['companyWebsiteUrl', 'companySize', 'companyLocation', 'companyPerks', 'companyLogoAvailable'])
      assert.ok(doc.components.schemas.JobDetailDto.properties[field]);
    assert.equal(doc.components.schemas.JobDetailDto.properties.companyPerks.type, 'array');
    assert.equal(doc.components.schemas.JobDetailDto.properties.companyLogoAvailable.type, 'boolean');
    assert.ok(!Object.keys(doc.paths).some(path => /companies\/[^/]+\/profile/.test(path)));
  } finally {
    if (app) await app.close();
    if (dataSource?.isInitialized) await dataSource.destroy();
    if (created) await admin.query('DROP DATABASE "' + database + '"');
    await admin.end();
  }
});
