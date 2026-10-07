import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import test from 'node:test';
import { Client } from 'pg';
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

// Only a dedicated test server is allowed. Never migrate the application DB.
test('IFND-153 selection, immutable snapshots, file retention, authorization and up/down', async () => {
  const port = Number(process.env.APPLICATION_DOCUMENTS_TEST_PORT);
  assert.ok(
    Number.isInteger(port) && port > 0 && port !== 5432,
    'Set APPLICATION_DOCUMENTS_TEST_PORT to a dedicated PostgreSQL port',
  );
  const database = `ifnd153_test_${randomUUID().replaceAll('-', '')}`;
  assert.match(database, /^ifnd153_test_[a-f0-9]{32}$/);
  const admin = new Client({
    host: '127.0.0.1',
    port,
    user: 'postgres',
    password: '',
    database: 'postgres',
  });
  await admin.connect();
  let source, app;
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
      JWT_SECRET: 'isolated-integration-only-secret',
      NODE_ENV: 'test',
    });
    const { AppDataSource } = await import('../dist/database/data-source.js');
    source = await AppDataSource.initialize();
    await source.runMigrations();
    const runner = source.createQueryRunner();
    const { CreateApplicationDocuments1791950000000 } =
      await import('../dist/database/migrations/1791950000000-create-application-documents.js');
    const migration = new CreateApplicationDocuments1791950000000();
    await migration.down(runner);
    const studentUserId = randomUUID(),
      studentId = randomUUID(),
      companyUserId = randomUUID(),
      companyId = randomUUID(),
      foreignUserId = randomUUID(),
      foreignStudentId = randomUUID();
    await source.query(
      `INSERT INTO users(id,email,password_hash,role) VALUES ($1,'student@example.test','unused','student'), ($2,'company@example.test','unused','company'), ($3,'foreign@example.test','unused','student')`,
      [studentUserId, companyUserId, foreignUserId],
    );
    await source.query(
      `INSERT INTO student_profiles(id,user_id,full_name) VALUES ($1,$2,'Student'), ($3,$4,'Foreign')`,
      [studentId, studentUserId, foreignStudentId, foreignUserId],
    );
    await source.query(
      `INSERT INTO company_profiles(id,user_id,name) VALUES ($1,$2,'Company')`,
      [companyId, companyUserId],
    );
    const jobs = [randomUUID(), randomUUID(), randomUUID(), randomUUID()];
    for (const id of jobs)
      await source.query(
        `INSERT INTO jobs(id,company_id,title,description,province,work_mode,category,has_allowance,requirements) VALUES ($1,$2,'Intern','Description','สงขลา','on_site','IT & Software',false,'Requirements')`,
        [id, companyId],
      );
    const legacyId = randomUUID();
    await source.query(
      `INSERT INTO applications(id,student_id,job_id,cover_letter,resume_object_key,resume_file_name) VALUES ($1,$2,$3,'Legacy','legacy/cv.pdf','Legacy CV.pdf')`,
      [legacyId, studentId, jobs[3]],
    );
    await migration.up(runner);
    assert.deepEqual(
      (
        await source.query(
          'SELECT type,file_name,object_key FROM application_documents WHERE application_id=$1',
          [legacyId],
        )
      )[0],
      { type: 'cv', file_name: 'Legacy CV.pdf', object_key: 'legacy/cv.pdf' },
    );
    await migration.down(runner); // Safe CV-only rollback preserves legacy columns.
    await migration.up(runner);

    const ids = {
      cv: randomUUID(),
      transcript: randomUUID(),
      other: randomUUID(),
      foreign: randomUUID(),
    };
    for (const [type, id] of Object.entries(ids))
      await source.query(
        `INSERT INTO student_documents(id,student_id,type,file_name,object_key) VALUES ($1,$2,$3,$4,$5)`,
        [
          id,
          type === 'foreign' ? foreignStudentId : studentId,
          type === 'foreign' ? 'other' : type,
          `${type}.pdf`,
          `original/${type}.pdf`,
        ],
      );
    const files = new Map(
      Object.keys(ids).map((type) => [
        `original/${type}.pdf`,
        Buffer.from(`%PDF-1.4 original ${type}`),
      ]),
    );
    const storage = {
      get: async (key) => files.get(key) ?? null,
      put: async (key, bytes) => files.set(key, bytes),
      delete: async (key) => files.delete(key),
    };
    const { ApplicationsRepository } =
      await import('../dist/applications/applications.repository.js');
    const { ApplicationsService } =
      await import('../dist/applications/applications.service.js');
    const { StudentsRepository } =
      await import('../dist/students/students.repository.js');
    const { StudentsService } =
      await import('../dist/students/students.service.js');
    const service = new ApplicationsService(
      new ApplicationsRepository(source),
      storage,
    );
    const students = new StudentsService(
      new StudentsRepository(source),
      storage,
      {},
      {},
    );
    const student = {
      userId: studentUserId,
      email: 'student@example.test',
      role: 'student',
    };
    const company = {
      userId: companyUserId,
      email: 'company@example.test',
      role: 'company',
    };
    const cvOnly = await service.apply(student, jobs[0], {
      coverLetter: 'CV only',
    });
    assert.deepEqual(
      (
        await service.getApplicantDetail(company, jobs[0], cvOnly.id)
      ).documents.map((d) => d.type),
      ['cv'],
    );
    const selected = await service.apply(student, jobs[1], {
      coverLetter: 'Selected files',
      documentIds: [ids.cv, ids.transcript, ids.other],
    });
    const snapshots = (
      await service.getApplicantDetail(company, jobs[1], selected.id)
    ).documents;
    assert.deepEqual(snapshots.map((d) => d.type).sort(), [
      'cv',
      'other',
      'transcript',
    ]);
    const transcript = snapshots.find((d) => d.type === 'transcript'),
      other = snapshots.find((d) => d.type === 'other');
    await students.uploadDocument(student, 'transcript', {
      originalname: 'New Transcript.pdf',
      buffer: Buffer.from('%PDF-1.4 new transcript'),
    });
    await students.uploadDocument(student, 'cv', {
      originalname: 'New CV.pdf',
      buffer: Buffer.from('%PDF-1.4 new CV'),
    });
    await students.deleteDocument(student, ids.other);
    assert.ok(
      files.has('original/transcript.pdf') &&
        files.has('original/other.pdf') &&
        files.has('original/cv.pdf'),
    );
    assert.equal(
      (
        await service.getApplicantDocument(
          company,
          jobs[1],
          selected.id,
          transcript.id,
        )
      ).buffer.toString(),
      '%PDF-1.4 original transcript',
    );
    assert.equal(
      (
        await service.getStudentApplicationDocument(
          student,
          selected.id,
          other.id,
        )
      ).buffer.toString(),
      '%PDF-1.4 original other',
    );
    assert.equal(
      (
        await service.getApplicantDocument(
          company,
          jobs[1],
          selected.id,
          transcript.id,
        )
      ).fileName,
      'transcript.pdf',
    );
    assert.equal(
      (
        await service.getApplicantResume(company, jobs[1], selected.id)
      ).toString(),
      '%PDF-1.4 original cv',
    );
    await assert.rejects(
      service.getApplicantDocument(company, jobs[0], cvOnly.id, transcript.id),
      /ไม่พบเอกสาร/,
    );
    await assert.rejects(
      service.getApplicantDocument(company, jobs[1], selected.id, ids.foreign),
      /ไม่พบเอกสาร/,
    );
    await assert.rejects(
      service.getStudentApplicationDocument(
        { ...student, userId: foreignUserId },
        selected.id,
        other.id,
      ),
      /ไม่พบใบสมัคร/,
    );
    await assert.rejects(
      service.getApplicantDocument(
        { ...company, userId: foreignUserId },
        jobs[1],
        selected.id,
        other.id,
      ),
      /ไม่พบโปรไฟล์บริษัท/,
    );
    await assert.rejects(
      service.apply(student, jobs[2], {
        coverLetter: 'Invalid',
        documentIds: [ids.foreign],
      }),
      /ไม่พบเอกสาร/,
    );
    await assert.rejects(
      service.apply(student, jobs[2], {
        coverLetter: 'Deleted',
        documentIds: [ids.other],
      }),
      /ไม่พบเอกสาร/,
    );
    assert.equal(
      (
        await source.query(
          'SELECT count(*)::int AS count FROM applications WHERE job_id=$1',
          [jobs[2]],
        )
      )[0].count,
      0,
    );
    await assert.rejects(
      service.apply(student, jobs[0], { coverLetter: 'Duplicate' }),
      /สมัคร/,
    );
    await assert.rejects(
      service.apply(student, jobs[2], { coverLetter: '   ' }),
      /Cover Letter/,
    );
    await assert.rejects(migration.down(runner), /Cannot rollback/);
    const { AppModule } = await import('../dist/app.module.js');
    app = await NestFactory.create(AppModule, { logger: false });
    app.setGlobalPrefix('api');
    await app.init();
    const swagger = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
    );
    assert.ok(swagger.components.schemas.ApplyJobDto.properties.documentIds);
    assert.ok(
      swagger.paths['/api/applications/{id}/documents/{documentId}/file'],
    );
    assert.ok(
      swagger.components.schemas.ApplicationDetailDto.properties.documents,
    );
    assert.ok(
      swagger.components.schemas.ApplicantDetailDto.properties.documents,
    );
    await runner.release();
  } finally {
    if (app) await app.close();
    if (source?.isInitialized) await source.destroy();
    if (created) await admin.query(`DROP DATABASE "${database}"`);
    await admin.end();
  }
});
