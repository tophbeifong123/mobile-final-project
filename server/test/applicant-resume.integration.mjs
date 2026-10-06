// Use only a separately started disposable PostgreSQL cluster.
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
import { ApplicationsController } from '../dist/applications/applications.controller.js';
import { ApplicationsRepository } from '../dist/applications/applications.repository.js';
import { ApplicationsService } from '../dist/applications/applications.service.js';
import { JwtAuthGuard } from '../dist/auth/jwt-auth.guard.js';
import { StorageService } from '../dist/storage/storage.service.js';

test('company resume API preserves the submitted snapshot, ownership and Swagger contract', async () => {
  const port = Number(process.env.APPLICANT_RESUME_INTEGRATION_PORT);
  assert.ok(
    Number.isInteger(port) && port > 5432 && port < 65536,
    'Use a disposable PostgreSQL port, not 5432',
  );
  const database = 'ifnd151_test_' + randomUUID().replaceAll('-', '');
  const admin = new Client({
    host: '127.0.0.1',
    port,
    user: 'postgres',
    database: 'postgres',
  });
  let source,
    app,
    created = false;
  await admin.connect();
  try {
    await admin.query('CREATE DATABASE "' + database + '"');
    created = true;
    source = new DataSource({
      ...AppDataSource.options,
      host: '127.0.0.1',
      port,
      username: 'postgres',
      password: '',
      database,
      synchronize: false,
      migrationsRun: false,
    });
    await source.initialize();
    await source.runMigrations();
    const companyUser = randomUUID(),
      otherUser = randomUUID(),
      studentUser = randomUUID();
    const companyId = randomUUID(),
      otherId = randomUUID(),
      studentId = randomUUID();
    const jobId = randomUUID(),
      otherJob = randomUUID();
    for (const [id, role] of [
      [companyUser, 'company'],
      [otherUser, 'company'],
      [studentUser, 'student'],
    ]) {
      await source.query(
        'INSERT INTO users (id,email,password_hash,role) VALUES ($1,$2,$3,$4)',
        [id, id + '@fixture.example', 'test-only-hash', role],
      );
    }
    for (const [id, user] of [
      [companyId, companyUser],
      [otherId, otherUser],
    ]) {
      await source.query(
        'INSERT INTO company_profiles (id,user_id,name,business_type,description) VALUES ($1,$2,$3,$4,$5)',
        [id, user, 'Company', 'IT', 'Company'],
      );
    }
    await source.query(
      'INSERT INTO student_profiles (id,user_id,full_name,university,major,resume_object_key,resume_file_name) VALUES ($1,$2,$3,$4,$5,$6,$7)',
      [
        studentId,
        studentUser,
        'Student',
        'University',
        'IT',
        'resumes/original.pdf',
        'original.pdf',
      ],
    );
    for (const [id, company] of [
      [jobId, companyId],
      [otherJob, otherId],
    ]) {
      await source.query(
        'INSERT INTO jobs (id,company_id,title,description,province,work_mode,category,has_allowance,requirements,status) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)',
        [
          id,
          company,
          'Intern',
          'Description',
          'สงขลา',
          'remote',
          'IT & Software',
          false,
          'None',
          'open',
        ],
      );
    }
    const original = Buffer.from('%PDF-1.4 original application document');
    const replacement = Buffer.from('%PDF-1.4 replacement profile document');
    let storageFailure = false;
    const storageKeys = [];
    const objects = new Map([
      ['resumes/original.pdf', original],
      ['resumes/new.pdf', replacement],
    ]);
    const module = await Test.createTestingModule({
      controllers: [ApplicationsController],
      providers: [
        ApplicationsService,
        {
          provide: ApplicationsRepository,
          useValue: new ApplicationsRepository(source),
        },
        {
          provide: StorageService,
          useValue: {
            get: async (key) => {
              storageKeys.push(key);
              if (storageFailure) throw new Error('private storage detail');
              return objects.get(key) ?? null;
            },
          },
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate(context) {
          const req = context.switchToHttp().getRequest();
          const account = req.headers['x-test-account'];
          if (!['owner', 'other', 'student'].includes(account))
            throw new UnauthorizedException();
          req.user = {
            userId:
              account === 'owner'
                ? companyUser
                : account === 'other'
                  ? otherUser
                  : studentUser,
            role: account === 'student' ? 'student' : 'company',
          };
          return true;
        },
      })
      .compile();
    app = module.createNestApplication({ logger: false });
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
    const http = request(app.getHttpServer());
    const submitted = (
      await http
        .post('/api/jobs/' + jobId + '/applications')
        .set('x-test-account', 'student')
        .send({ coverLetter: 'My cover letter' })
        .expect(201)
    ).body;
    const path = '/api/company/jobs/' + jobId + '/applications/' + submitted.id;
    await source.query(
      'UPDATE student_profiles SET resume_object_key=$1,resume_file_name=$2 WHERE id=$3',
      ['resumes/new.pdf', 'new.pdf', studentId],
    );
    const detail = (
      await http.get(path).set('x-test-account', 'owner').expect(200)
    ).body;
    assert.equal(detail.resumeObjectKey, 'resumes/original.pdf');
    assert.notEqual(detail.resumeFileName, 'new.pdf');
    const response = await http
      .get(path + '/resume')
      .set('x-test-account', 'owner')
      .expect(200);
    assert.deepEqual(response.body, original);
    assert.match(response.headers['content-type'], /application\/pdf/);
    assert.equal(
      response.headers['content-disposition'],
      'inline; filename="application-resume.pdf"',
    );
    assert.equal(response.headers['cache-control'], 'private, no-store');
    assert.equal(response.headers['x-content-type-options'], 'nosniff');
    assert.deepEqual(storageKeys, ['resumes/original.pdf']);
    await http.get(path + '/resume').expect(401);
    await http
      .get(path + '/resume')
      .set('x-test-account', 'student')
      .expect(403);
    await http
      .get(path + '/resume')
      .set('x-test-account', 'other')
      .expect(403);
    await http
      .get(
        '/api/company/jobs/' +
          otherJob +
          '/applications/' +
          submitted.id +
          '/resume',
      )
      .set('x-test-account', 'other')
      .expect(404);
    await http
      .get(
        '/api/company/jobs/' +
          jobId +
          '/applications/' +
          randomUUID() +
          '/resume',
      )
      .set('x-test-account', 'owner')
      .expect(404);
    await http
      .get(path.replace(submitted.id, 'not-a-uuid') + '/resume')
      .set('x-test-account', 'owner')
      .expect(400);
    assert.deepEqual(storageKeys, ['resumes/original.pdf']);
    objects.delete('resumes/original.pdf');
    await http
      .get(path + '/resume')
      .set('x-test-account', 'owner')
      .expect(404);
    storageFailure = true;
    const failure = await http
      .get(path + '/resume')
      .set('x-test-account', 'owner')
      .expect(503);
    assert.ok(!JSON.stringify(failure.body).includes('private storage detail'));
    // Status rules remain submitted -> reviewing -> accepted/rejected.
    await http
      .patch(path + '/status')
      .set('x-test-account', 'owner')
      .send({ status: 'accepted' })
      .expect(400);
    await http
      .patch(path + '/status')
      .set('x-test-account', 'owner')
      .send({ status: 'reviewing' })
      .expect(200);
    await http
      .patch(path + '/status')
      .set('x-test-account', 'owner')
      .send({ status: 'accepted' })
      .expect(200);
    await http
      .patch(path + '/status')
      .set('x-test-account', 'owner')
      .send({ status: 'rejected' })
      .expect(400);
    const doc = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
    );
    const route =
      doc.paths['/api/company/jobs/{id}/applications/{applicationId}/resume']
        .get;
    assert.equal(
      route.responses['200'].content['application/pdf'].schema.format,
      'binary',
    );
    for (const status of ['400', '401', '403', '404', '503'])
      assert.ok(route.responses[status]);
    assert.ok(route.security.length);
  } finally {
    if (app) await app.close();
    if (source?.isInitialized) await source.destroy();
    if (created) await admin.query('DROP DATABASE "' + database + '"');
    await admin.end();
  }
});
