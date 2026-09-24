import { randomUUID } from 'node:crypto';
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { UserRole } from '../auth/user-role.js';
import { StorageService } from '../storage/storage.service.js';
import { type UploadedFilePayload } from '../storage/uploaded-file.interface.js';
import { ResumeResponseDto } from './dto/resume-response.dto.js';
import { StudentProfileDto } from './dto/student-profile.dto.js';
import { UpdateStudentProfileDto } from './dto/update-student-profile.dto.js';
import { StudentsRepository } from './students.repository.js';

const STUDENT_ONLY = 'เฉพาะนักศึกษาเท่านั้น';
const PROFILE_NOT_FOUND = 'ไม่พบโปรไฟล์';
const ONLY_PDF_ALLOWED = 'เลือกได้เฉพาะไฟล์ PDF เท่านั้น';
const FILE_REQUIRED = 'กรุณาเลือกไฟล์ PDF';
const RESUME_NOT_FOUND = 'ไม่พบไฟล์ Resume';

@Injectable()
export class StudentsService {
  constructor(
    private readonly studentsRepository: StudentsRepository,
    private readonly storageService: StorageService,
  ) {}

  async getMine(user: AuthUser): Promise<StudentProfileDto> {
    this.assertStudent(user);
    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    return toDto(profile);
  }

  async updateMine(
    user: AuthUser,
    dto: UpdateStudentProfileDto,
  ): Promise<StudentProfileDto> {
    this.assertStudent(user);
    const saved = await this.studentsRepository.updateByUserId(user.userId, {
      fullName: dto.fullName.trim(),
      university: dto.university.trim(),
      major: dto.major.trim(),
      skills: dto.skills
        .map((skill) => skill.trim())
        .filter((skill) => skill.length > 0),
      portfolioUrl: dto.portfolioUrl?.trim() || null,
    });
    if (!saved) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    return toDto(saved);
  }

  async uploadResume(
    user: AuthUser,
    file: UploadedFilePayload | undefined,
  ): Promise<ResumeResponseDto> {
    this.assertStudent(user);
    if (!file) {
      throw new BadRequestException(FILE_REQUIRED);
    }

    const isPdfMagic =
      file.buffer &&
      file.buffer.length >= 4 &&
      file.buffer.subarray(0, 4).toString() === '%PDF';

    const hasPdfExt = file.originalname?.toLowerCase().endsWith('.pdf');
    const isPdfMime =
      file.mimetype === 'application/pdf' ||
      file.mimetype === 'application/x-pdf' ||
      file.mimetype === 'application/acrobat' ||
      file.mimetype === 'applications/vnd.pdf' ||
      file.mimetype === 'text/pdf';

    const isGenericMime =
      !file.mimetype ||
      file.mimetype === 'application/octet-stream' ||
      file.mimetype === 'binary/octet-stream';

    // Must either match PDF magic bytes (%PDF) or have PDF extension/mime
    const isPdf = isPdfMagic || (hasPdfExt && isGenericMime) || isPdfMime;

    // If buffer exists and has at least 4 bytes, verify it does not have invalid header
    if (!isPdf || (file.buffer && file.buffer.length >= 4 && !isPdfMagic && !hasPdfExt)) {
      throw new BadRequestException(ONLY_PDF_ALLOWED);
    }

    let fileName = file.originalname?.trim() || 'resume.pdf';
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      fileName += '.pdf';
    }

    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    const objectKey = `resumes/${user.userId}/${Date.now()}-${randomUUID()}.pdf`;
    await this.storageService.put(objectKey, file.buffer, 'application/pdf');

    const updated = await this.studentsRepository.updateResume(
      user.userId,
      objectKey,
      fileName,
    );
    if (!updated) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    return {
      fileName: updated.resumeFileName ?? fileName,
      objectKey: updated.resumeObjectKey ?? objectKey,
    };
  }

  async getResumeFile(
    user: AuthUser,
  ): Promise<{ buffer: Buffer; fileName: string }> {
    this.assertStudent(user);
    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    if (!profile.resumeObjectKey) {
      throw new NotFoundException(RESUME_NOT_FOUND);
    }
    const buffer = await this.storageService.get(profile.resumeObjectKey);
    if (!buffer) {
      throw new NotFoundException(RESUME_NOT_FOUND);
    }
    return {
      buffer,
      fileName: profile.resumeFileName || 'resume.pdf',
    };
  }

  private assertStudent(user: AuthUser): void {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
  }
}

function toDto(profile: {
  fullName: string;
  university: string;
  major: string;
  skills: string[];
  portfolioUrl: string | null;
  resumeFileName?: string | null;
  resumeObjectKey?: string | null;
}): StudentProfileDto {
  const dto = new StudentProfileDto();
  dto.fullName = profile.fullName;
  dto.university = profile.university;
  dto.major = profile.major;
  dto.skills = profile.skills;
  dto.portfolioUrl = profile.portfolioUrl;
  dto.resumeFileName = profile.resumeFileName ?? null;
  dto.resumeObjectKey = profile.resumeObjectKey ?? null;
  return dto;
}

