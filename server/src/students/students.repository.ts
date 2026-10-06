import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';
import { University } from '../universities/university.entity.js';
import { Major } from '../majors/major.entity.js';

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
    objectKey: string,
    fileName: string,
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

