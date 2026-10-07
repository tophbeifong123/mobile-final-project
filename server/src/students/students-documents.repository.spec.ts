import { NotFoundException } from '@nestjs/common';
import { type DataSource } from 'typeorm';
import { StudentsRepository, TooManyOtherDocumentsError } from './students.repository.js';
import { StudentDocumentType } from './student-document.entity.js';

describe('document replacement transaction', () => {
  function fixture() {
    const query = { setLock: vi.fn().mockReturnThis(), where: vi.fn().mockReturnThis(), getOne: vi.fn().mockResolvedValue({}) };
    const documents = { findOne: vi.fn(), count: vi.fn().mockResolvedValue(3), remove: vi.fn(), create: vi.fn((input) => input), save: vi.fn(async (input) => input) };
    const manager = { createQueryBuilder: vi.fn(() => query), getRepository: vi.fn(() => documents), update: vi.fn() };
    const source = { transaction: vi.fn(async (callback) => callback(manager)) };
    const repository = new StudentsRepository(source as unknown as DataSource);
    return { repository, documents, query, manager };
  }
  const input = { studentId: 'student-1', type: StudentDocumentType.Other, objectKey: 'new.pdf', fileName: 'new.pdf' };
  it('replaces exactly the owned other file at the three-file limit under the student lock', async () => {
    const view = fixture();
    const old = { id: 'old-id', objectKey: 'old.pdf' };
    view.documents.findOne.mockResolvedValue(old);
    const result = await view.repository.saveDocument({ ...input, replacingId: 'old-id' });
    expect(view.query.setLock).toHaveBeenCalledWith('pessimistic_write');
    expect(view.documents.findOne).toHaveBeenCalledWith({ where: { id: 'old-id', studentId: 'student-1', type: 'other' } });
    expect(view.documents.count).not.toHaveBeenCalled();
    expect(view.documents.remove).toHaveBeenCalledWith(old);
    expect(result.replacedDocument).toBe(old);
    expect(view.documents.create).toHaveBeenCalledWith(input);
  });
  it('rejects a stale/foreign replacement without deleting or saving', async () => {
    const view = fixture(); view.documents.findOne.mockResolvedValue(null);
    await expect(view.repository.saveDocument({ ...input, replacingId: 'old-id' })).rejects.toBeInstanceOf(NotFoundException);
    expect(view.documents.remove).not.toHaveBeenCalled();
    expect(view.documents.save).not.toHaveBeenCalled();
  });
  it('still rejects a fourth addition', async () => {
    const view = fixture();
    await expect(view.repository.saveDocument(input)).rejects.toBeInstanceOf(TooManyOtherDocumentsError);
    expect(view.documents.remove).not.toHaveBeenCalled();
    expect(view.documents.save).not.toHaveBeenCalled();
  });
  it.each([StudentDocumentType.Cv, StudentDocumentType.Transcript])('replaces the sole %s rather than adding another file', async (type) => {
    const view = fixture(); const old = { id: 'old', objectKey: 'old.pdf' }; view.documents.findOne.mockResolvedValue(old);
    await view.repository.saveDocument({ ...input, type });
    expect(view.documents.remove).toHaveBeenCalledWith(old);
    if (type === StudentDocumentType.Cv) expect(view.manager.update).toHaveBeenCalledWith(expect.anything(), { id: input.studentId }, { resumeObjectKey: 'new.pdf', resumeFileName: 'new.pdf' });
  });
});
