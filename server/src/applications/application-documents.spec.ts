import { describe, it, expect, vi } from 'vitest';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { selectApplicationDocuments } from './application-document-selection.js';
import {
  StudentDocument,
  StudentDocumentType,
} from '../students/student-document.entity.js';
import { ApplicationsRepository } from './applications.repository.js';
import { ApplicationsService } from './applications.service.js';
import { ApplicationDocument } from './entities/application-document.entity.js';
import { Application } from './entities/application.entity.js';
import { ApplicationStatusEvent } from './entities/application-status-event.entity.js';
import { DataSource } from 'typeorm';
import { StorageService } from '../storage/storage.service.js';
import { UserRole } from '../auth/user-role.js';
import { CreateApplicationDocuments1791950000000 } from '../database/migrations/1791950000000-create-application-documents.js';

const doc = (id: string, type: StudentDocumentType) =>
  Object.assign(new StudentDocument(), {
    id,
    studentId: 'student',
    type,
    fileName: `${id}.pdf`,
    objectKey: `original/${id}.pdf`,
  });
const library = [
  doc('cv', StudentDocumentType.Cv),
  doc('transcript', StudentDocumentType.Transcript),
  doc('other', StudentDocumentType.Other),
];
const user = {
  userId: 'user',
  email: 'student@example.com',
  role: UserRole.Student,
};

describe('application document service policy', () => {
  it.each([undefined, []])(
    'defaults to CV only, without optional files (%s)',
    (ids) => {
      expect(selectApplicationDocuments(library, ids)).toEqual([library[0]]);
    },
  );
  it('includes only the chosen optional files and never duplicates the CV', () => {
    expect(selectApplicationDocuments(library, ['cv', 'other'])).toEqual([
      library[0],
      library[2],
    ]);
  });
  it.each([['foreign'], ['deleted'], ['cv', 'cv'], Array(6).fill('cv')])(
    'rejects invalid selection %s',
    (...ids) => {
      expect(() =>
        selectApplicationDocuments(library, ids as string[]),
      ).toThrow(BadRequestException);
    },
  );
  it('requires an actual current CV even if legacy profile has a filename', () => {
    expect(() => selectApplicationDocuments(library.slice(1), [])).toThrow(
      BadRequestException,
    );
  });
  it('service refuses foreign selection before attempting to create an application', async () => {
    const repo = {
      findStudentProfileByUserId: vi.fn().mockResolvedValue({ id: 'student' }),
      findStudentDocuments: vi.fn().mockResolvedValue(library),
      applyJob: vi.fn(),
    };
    const service = new ApplicationsService(
      repo as unknown as ApplicationsRepository,
      {} as StorageService,
    );
    await expect(
      service.apply(user, 'job', {
        coverLetter: 'Hello',
        documentIds: ['foreign'],
      }),
    ).rejects.toThrow(BadRequestException);
    expect(repo.applyJob).not.toHaveBeenCalled();
  });
});

describe('transactional snapshot persistence', () => {
  const params = {
    studentId: 'student',
    jobId: 'job',
    coverLetter: 'Hello',
    resumeObjectKey: 'stale',
    resumeFileName: 'stale.pdf',
    actorUserId: 'user',
  };
  function setup(documents = library) {
    const query = {
      setLock: vi.fn().mockReturnThis(),
      where: vi.fn().mockReturnThis(),
      getOne: vi.fn().mockResolvedValue({ id: 'job', status: 'open' }),
    };
    const manager = {
      createQueryBuilder: vi.fn().mockReturnValue(query),
      find: vi.fn().mockResolvedValue(documents),
      findOne: vi.fn().mockResolvedValue(null),
      create: vi.fn((_entity, data) => data),
      save: vi.fn(async (_entity, data) =>
        Array.isArray(data) ? data : { ...data, id: 'application' },
      ),
    };
    const repo = new ApplicationsRepository({
      transaction: (fn: (m: typeof manager) => unknown) => fn(manager),
    } as unknown as DataSource);
    return { repo, manager, query };
  }
  it('saves CV + selected optional metadata and object keys, with the event in one transaction', async () => {
    const { repo, manager, query } = setup();
    await repo.applyJob({ ...params, documentIds: ['other'] });
    expect(query.setLock).toHaveBeenCalledWith('pessimistic_write');
    expect(manager.save).toHaveBeenCalledWith(ApplicationDocument, [
      {
        applicationId: 'application',
        type: 'cv',
        fileName: 'cv.pdf',
        objectKey: 'original/cv.pdf',
      },
      {
        applicationId: 'application',
        type: 'other',
        fileName: 'other.pdf',
        objectKey: 'original/other.pdf',
      },
    ]);
    expect(manager.save).toHaveBeenCalledWith(
      ApplicationStatusEvent,
      expect.objectContaining({ applicationId: 'application' }),
    );
    expect(manager.create).toHaveBeenCalledWith(
      Application,
      expect.objectContaining({ resumeObjectKey: 'original/cv.pdf' }),
    );
  });
  it('persists only CV when no optional files were selected', async () => {
    const { repo, manager } = setup();
    await repo.applyJob(params);
    expect(manager.save).toHaveBeenCalledWith(ApplicationDocument, [
      expect.objectContaining({ type: 'cv' }),
    ]);
  });
  it('revalidates deleted selection after locking, and makes no writes', async () => {
    const { repo, manager } = setup([library[0]]);
    await expect(
      repo.applyJob({ ...params, documentIds: ['other'] }),
    ).rejects.toThrow(BadRequestException);
    expect(manager.save).not.toHaveBeenCalled();
  });
  it('does not resurrect a deleted CV from prefetched profile fields', async () => {
    const { repo, manager } = setup([]);
    await expect(repo.applyJob(params)).rejects.toThrow(BadRequestException);
    expect(manager.save).not.toHaveBeenCalled();
  });
  it('never joins the mutable library when listing or reading snapshots', async () => {
    const snapshot = {
      id: 'snapshot',
      applicationId: 'application',
      type: 'other',
      fileName: 'original.pdf',
      objectKey: 'original/other.pdf',
    };
    const appRepo = {
      findOne: vi.fn().mockResolvedValue({ id: 'application', jobId: 'job' }),
    };
    const snapRepo = {
      find: vi.fn().mockResolvedValue([snapshot]),
      findOne: vi.fn().mockResolvedValue(snapshot),
    };
    const getRepository = vi.fn((entity) => {
      if (entity === Application) return appRepo;
      if (entity === ApplicationDocument) return snapRepo;
      throw new Error('Library must not be read');
    });
    const repo = new ApplicationsRepository({
      getRepository,
    } as unknown as DataSource);
    expect(await repo.listApplicantDocuments('job', 'application')).toEqual([
      expect.objectContaining({ id: 'snapshot', fileName: 'original.pdf' }),
    ]);
    expect(
      await repo.findApplicantDocument('job', 'application', 'snapshot'),
    ).toEqual({ objectKey: 'original/other.pdf', fileName: 'original.pdf' });
    expect(snapRepo.findOne).toHaveBeenCalledWith({
      where: { id: 'snapshot', applicationId: 'application' },
    });
  });
});

describe('snapshot authorization and storage', () => {
  it('student cannot read another application or unselected document', async () => {
    const repo = {
      findStudentProfileByUserId: vi.fn().mockResolvedValue({ id: 'student' }),
      findApplicationDetail: vi.fn().mockResolvedValue(null),
      findApplicantDocument: vi.fn(),
    };
    const storage = { get: vi.fn() };
    const service = new ApplicationsService(
      repo as unknown as ApplicationsRepository,
      storage as unknown as StorageService,
    );
    await expect(
      service.getStudentApplicationDocument(user, 'foreign', 'snapshot'),
    ).rejects.toThrow(NotFoundException);
    expect(storage.get).not.toHaveBeenCalled();
    expect(repo.findApplicationDetail).toHaveBeenCalledWith(
      'foreign',
      'student',
    );
  });
  it('company cannot request a library file that was never attached', async () => {
    const repo = {
      findCompanyProfileByUserId: vi.fn().mockResolvedValue({ id: 'company' }),
      findJobById: vi.fn().mockResolvedValue({ companyId: 'company' }),
      findCompanyApplicantDetail: vi
        .fn()
        .mockResolvedValue({
          createdAt: new Date(),
          updatedAt: new Date(),
          documents: [],
        }),
      findApplicantDocument: vi.fn(),
    };
    const storage = { get: vi.fn() };
    const service = new ApplicationsService(
      repo as unknown as ApplicationsRepository,
      storage as unknown as StorageService,
    );
    await expect(
      service.getApplicantDocument(
        { ...user, role: UserRole.Company },
        'job',
        'app',
        'library-other',
      ),
    ).rejects.toThrow(NotFoundException);
    expect(repo.findApplicantDocument).not.toHaveBeenCalled();
    expect(storage.get).not.toHaveBeenCalled();
  });
});

describe('migration safety', () => {
  it('backfills CV only and supports safe rollback without deleting objects', async () => {
    const runner = { query: vi.fn().mockResolvedValue([{ count: 0 }]) };
    const migration = new CreateApplicationDocuments1791950000000();
    await migration.up(runner as any);
    expect(runner.query.mock.calls.map(([sql]) => sql).join('\n')).toContain(
      "SELECT id, 'cv'",
    );
    await migration.down(runner as any);
    expect(runner.query).toHaveBeenCalledWith(
      'DROP TABLE application_documents',
    );
  });
  it('refuses destructive rollback with selected optional snapshots', async () => {
    const runner = { query: vi.fn().mockResolvedValue([{ count: 1 }]) };
    await expect(
      new CreateApplicationDocuments1791950000000().down(runner as any),
    ).rejects.toThrow('Cannot rollback');
    expect(runner.query).toHaveBeenCalledTimes(1);
  });
});
