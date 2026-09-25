import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { StudentProfile } from '../auth/entities/student-profile.entity.js';

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
  university: string;
  major: string;
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
    profile.university = input.university;
    profile.major = input.major;
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

