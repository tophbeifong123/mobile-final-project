import 'reflect-metadata';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { Client } from 'pg';
import { DataSource } from 'typeorm';
import { Test } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import request from 'supertest';
import { AppDataSource } from '../dist/database/data-source.js';
import { CompaniesController } from '../dist/companies/companies.controller.js';
import { CompaniesRepository } from '../dist/companies/companies.repository.js';
import { CompaniesService } from '../dist/companies/companies.service.js';
import { JwtAuthGuard } from '../dist/auth/jwt-auth.guard.js';
import { StorageService } from '../dist/storage/storage.service.js';
import { ProvincesService } from '../dist/provinces/provinces.service.js';
import { ProvincesRepository } from '../dist/provinces/provinces.repository.js';

// Dedicated test cluster only; never migrate an existing application database.
test('dashboard counts live company data, pending states and Swagger', async () => {
  const port = Number(process.env.DASHBOARD_INTEGRATION_PORT);
  assert.ok(Number.isInteger(port) && port > 5432 && port < 65536,
    'Set DASHBOARD_INTEGRATION_PORT to a dedicated local test PostgreSQL port');
  const database = 'ifnd142_test_' + randomUUID().replaceAll('-', '');
  const admin = new Client({ host: '127.0.0.1', port, user: 'postgres', database: 'postgres' });
  let source, app, created = false;
  await admin.connect();
  try {
    await admin.query('CREATE DATABASE "' + database + '"');
    created = true;
    source = new DataSource({ ...AppDataSource.options, host: '127.0.0.1', port,
      username: 'postgres', password: '', database, synchronize: false });
    await source.initialize();
    await source.runMigrations();
    const companyUsers = [randomUUID(), randomUUID(), randomUUID()];
    const companies = [randomUUID(), randomUUID(), randomUUID()];
    for (let i = 0; i < companies.length; i++) {
      await source.query('INSERT INTO users(id,email,password_hash,role) VALUES($1,$2,$3,$4)',
        [companyUsers[i], `company-${i}@fixture.test`, 'unused', 'company']);
      await source.query('INSERT INTO company_profiles(id,user_id,name) VALUES($1,$2,$3)',
        [companies[i], companyUsers[i], `Company ${i}`]);
    }
    const studentUser = randomUUID(), studentId = randomUUID();
    await source.query('INSERT INTO users(id,email,password_hash,role) VALUES($1,$2,$3,$4)',
      [studentUser, 'student@fixture.test', 'unused', 'student']);
    await source.query('INSERT INTO student_profiles(id,user_id) VALUES($1,$2)', [studentId, studentUser]);
    const jobs = [];
    for (const [companyId, status] of [[companies[0], 'open'], [companies[0], 'closed'], [companies[0], 'draft'], [companies[1], 'open']]) {
      const id = randomUUID(); jobs.push(id);
      await source.query(`INSERT INTO jobs(id,company_id,title,description,province,work_mode,category,has_allowance,requirements,status)
        VALUES($1,$2,'Intern','Test','สงขลา','on_site','IT',false,'Test',$3)`, [id, companyId, status]);
    }
    const appIds = [];
    for (const [jobId, status] of [[jobs[0], 'submitted'], [jobs[1], 'reviewing'], [jobs[3], 'submitted']]) {
      const id = randomUUID(); appIds.push(id);
      await source.query(`INSERT INTO applications(id,student_id,job_id,cover_letter,resume_object_key,status)
        VALUES($1,$2,$3,'Test','fixture.pdf',$4)`, [id, studentId, jobId, status]);
    }
    const module = await Test.createTestingModule({
      controllers: [CompaniesController], providers: [CompaniesService,
        { provide: ProvincesService, useValue: new ProvincesService(new ProvincesRepository(source)) },
        { provide: CompaniesRepository, useValue: new CompaniesRepository(source) },
        { provide: StorageService, useValue: {} },
      ],
    }).overrideGuard(JwtAuthGuard).useValue({ canActivate(context) {
      const req = context.switchToHttp().getRequest();
      const role = req.headers['x-test-role'];
      if (role !== 'company' && role !== 'student') throw new UnauthorizedException();
      req.user = { userId: role === 'company' ? companyUsers[Number(req.headers['x-test-company'] ?? 0)] : studentUser, role };
      return true;
    } }).compile();
    app = module.createNestApplication({ logger: false });
    app.setGlobalPrefix('api'); await app.init();
    const http = request(app.getHttpServer());
    const read = (index = 0) => http.get('/api/companies/me/dashboard').set('x-test-role', 'company').set('x-test-company', String(index)).expect(200);
    assert.deepEqual((await read()).body, { totalJobs: 3, openJobs: 1, totalApplicants: 2, pendingApplicants: 2 });
    assert.deepEqual((await read(1)).body, { totalJobs: 1, openJobs: 1, totalApplicants: 1, pendingApplicants: 1 });
    assert.deepEqual((await read(2)).body, { totalJobs: 0, openJobs: 0, totalApplicants: 0, pendingApplicants: 0 });
    // Finished statuses do not count as pending. Reopening reads fresh data.
    await source.query("UPDATE applications SET status='accepted' WHERE id=$1", [appIds[0]]);
    await source.query("UPDATE applications SET status='rejected' WHERE id=$1", [appIds[1]]);
    assert.deepEqual((await read()).body, { totalJobs: 3, openJobs: 1, totalApplicants: 2, pendingApplicants: 0 });
    await http.get('/api/companies/me/dashboard').set('x-test-role', 'student').expect(403);
    await http.get('/api/companies/me/dashboard').expect(401);
    const doc = SwaggerModule.createDocument(app, new DocumentBuilder().setTitle('Test').addBearerAuth().build());
    assert.ok(doc.paths['/api/companies/me/dashboard'].get);
    const pending = doc.components.schemas.CompanyDashboardSummaryDto.properties.pendingApplicants;
    assert.equal(pending.type, 'integer'); assert.equal(pending.minimum, 0);
    assert.ok(doc.components.schemas.CompanyDashboardSummaryDto.required.includes('pendingApplicants'));
  } finally {
    if (app) await app.close();
    if (source?.isInitialized) await source.destroy();
    if (created) await admin.query('DROP DATABASE "' + database + '"');
    await admin.end();
  }
});
