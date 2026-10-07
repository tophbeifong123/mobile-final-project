import { Injectable } from '@nestjs/common';
import { DataSource, type EntityManager } from 'typeorm';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { Major } from '../majors/major.entity.js';
import { University } from '../universities/university.entity.js';
import { StudentDocument, StudentDocumentType } from './student-document.entity.js';

export interface ContactLinkRecord {
  id?: string;
  platform: string;
  label?: string;
  value: string;
}

export interface PortfolioLinkRecord {
  id?: string;
  title: string;
  url: string;
  description?: string;
}

export interface StudentProfileUpdate {
  fullName: string;
  universityId?: string | null;
  customUniversityName?: string | null;
  majorId?: string | null;
  customMajorName?: string | null;
  skills: string[];
  bio?: string;
  contactLinks?: ContactLinkRecord[];
  portfolioLinks?: PortfolioLinkRecord[];
  portfolioUrl?: string | null;
}

@Injectable()
export class StudentsRepository {
  constructor(private readonly dataSource: DataSource) {}

  findByUserId(userId: string): Promise<StudentProfile | null> {
    return this.dataSource
      .getRepository(StudentProfile)
      .findOne({ where: { userId } });
  }

  async resolveDisplayUniversity(profile: StudentProfile): Promise<string> {
    if (!profile.universityId) return profile.customUniversityName ?? '';
    const university = await this.dataSource.getRepository(University).findOne({
      where: { id: profile.universityId },
    });
    return university?.nameTh ?? '';
  }

  async resolveDisplayMajor(profile: StudentProfile): Promise<string> {
    if (!profile.majorId) return profile.customMajorName ?? '';
    const major = await this.dataSource.getRepository(Major).findOne({
      where: { id: profile.majorId },
    });
    return major?.nameTh ?? '';
  }

  listDocuments(studentId: string): Promise<StudentDocument[]> {
    return this.dataSource.getRepository(StudentDocument).find({
      where: { studentId },
      order: { createdAt: 'ASC' },
    });
  }

  findDocument(studentId: string, id: string): Promise<StudentDocument | null> {
    return this.dataSource.getRepository(StudentDocument).findOne({
      where: { studentId, id },
    });
  }

  findCv(studentId: string): Promise<StudentDocument | null> {
    return this.dataSource.getRepository(StudentDocument).findOne({
      where: { studentId, type: StudentDocumentType.Cv },
    });
  }

  findCvOrType(studentId: string, type: StudentDocumentType): Promise<StudentDocument | null> {
    return this.dataSource.getRepository(StudentDocument).findOne({ where: { studentId, type } });
  }

  async saveDocument(input: {
    studentId: string;
    type: StudentDocumentType;
    objectKey: string;
    fileName: string;
  }): Promise<{ document: StudentDocument; replacedDocument: StudentDocument | null }> {
    return this.dataSource.transaction(async (manager) => {
      await this.lockStudent(manager, input.studentId);
      const documents = manager.getRepository(StudentDocument);
      if (input.type === StudentDocumentType.Other) {
        const count = await documents.count({
          where: { studentId: input.studentId, type: input.type },
        });
        if (count >= 3) throw new TooManyOtherDocumentsError();
      }
      let replacedDocument: StudentDocument | null = null;
      if (input.type !== StudentDocumentType.Other) {
        replacedDocument = await documents.findOne({
          where: { studentId: input.studentId, type: input.type },
        });
        if (replacedDocument) await documents.remove(replacedDocument);
      }
      const document = await documents.save(documents.create(input));
      if (input.type === StudentDocumentType.Cv) {
        await manager.update(
          StudentProfile,
          { id: input.studentId },
          { resumeObjectKey: input.objectKey, resumeFileName: input.fileName },
        );
      }
      return { document, replacedDocument };
    });
  }

  async deleteDocument(studentId: string, id: string): Promise<StudentDocument | null> {
    return this.dataSource.transaction(async (manager) => {
      await this.lockStudent(manager, studentId);
      const documents = manager.getRepository(StudentDocument);
      const document = await documents.findOne({
        where: { id, studentId },
      });
      if (document) {
        await documents.remove(document);
        if (document.type === StudentDocumentType.Cv) {
          await manager.update(
            StudentProfile,
            { id: studentId },
            { resumeObjectKey: null, resumeFileName: null },
          );
        }
      }
      return document;
    });
  }

  async isObjectReferencedByApplication(objectKey: string): Promise<boolean> {
    const rows = await this.dataSource.query(
      'SELECT 1 FROM applications WHERE resume_object_key = $1 LIMIT 1',
      [objectKey],
    );
    return rows.length > 0;
  }

  private async lockStudent(manager: EntityManager, studentId: string): Promise<void> {
    await manager
      .createQueryBuilder(StudentProfile, 'student')
      .setLock('pessimistic_write')
      .where('student.id = :studentId', { studentId })
      .getOne();
  }

  async updateByUserId(
    userId: string,
    input: StudentProfileUpdate,
  ): Promise<StudentProfile | null> {
    const profiles = this.dataSource.getRepository(StudentProfile);
    const profile = await profiles.findOne({ where: { userId } });
    if (!profile) {
      return null;
    }

    profile.fullName = input.fullName;
    if (input.universityId !== undefined || input.customUniversityName !== undefined) {
      profile.universityId = input.universityId ?? null;
      profile.customUniversityName = input.customUniversityName ?? null;
    }
    if (input.majorId !== undefined || input.customMajorName !== undefined) {
      profile.majorId = input.majorId ?? null;
      profile.customMajorName = input.customMajorName ?? null;
    }
    profile.skills = input.skills;
    if (input.bio !== undefined) {
      profile.bio = input.bio;
    }
    if (input.contactLinks !== undefined) {
      profile.contactLinks = input.contactLinks;
    }
    if (input.portfolioLinks !== undefined) {
      profile.portfolioLinks = input.portfolioLinks;
    }
    if (input.portfolioUrl !== undefined) {
      profile.portfolioUrl = input.portfolioUrl;
    }
    return profiles.save(profile);
  }

  async updateResume(
    userId: string,
    objectKey: string | null,
    fileName: string | null,
  ): Promise<StudentProfile | null> {
    const profiles = this.dataSource.getRepository(StudentProfile);
    const profile = await profiles.findOne({ where: { userId } });
    if (!profile) {
      return null;
    }

    profile.resumeObjectKey = objectKey;
    profile.resumeFileName = fileName;
    return profiles.save(profile);
  }

  async updateAvatar(
    userId: string,
    objectKey: string | null,
  ): Promise<StudentProfile | null> {
    const profiles = this.dataSource.getRepository(StudentProfile);
    const profile = await profiles.findOne({ where: { userId } });
    if (!profile) {
      return null;
    }

    profile.avatarObjectKey = objectKey;
    return profiles.save(profile);
  }
}

export class TooManyOtherDocumentsError extends Error {}

