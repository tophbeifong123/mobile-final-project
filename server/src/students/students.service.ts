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

    const contactLinks = dto.contactLinks
      ? dto.contactLinks.map((item) => ({
          id: item.id || randomUUID(),
          platform: item.platform.trim(),
          label: item.label?.trim() || undefined,
          value: item.value.trim(),
        }))
      : undefined;

    const portfolioLinks = dto.portfolioLinks
      ? dto.portfolioLinks.map((item) => ({
          id: item.id || randomUUID(),
          title: item.title.trim(),
          url: item.url.trim(),
          description: item.description?.trim() || undefined,
        }))
      : undefined;

    let portfolioUrl = dto.portfolioUrl?.trim() || null;
    if (!portfolioUrl && portfolioLinks && portfolioLinks.length > 0) {
      portfolioUrl = portfolioLinks[0].url;
    }

    const saved = await this.studentsRepository.updateByUserId(user.userId, {
      fullName: dto.fullName.trim(),
      university: dto.university.trim(),
      major: dto.major.trim(),
      skills: dto.skills
        .map((skill) => skill.trim())
        .filter((skill) => skill.length > 0),
      bio: dto.bio !== undefined ? dto.bio.trim() : undefined,
      contactLinks,
      portfolioLinks,
      portfolioUrl,
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

  async uploadAvatar(
    user: AuthUser,
    file: UploadedFilePayload | undefined,
  ): Promise<StudentProfileDto> {
    this.assertStudent(user);
    if (!file) {
      throw new BadRequestException('กรุณาเลือกไฟล์รูปภาพ');
    }

    const isPng =
      file.buffer &&
      file.buffer.length >= 8 &&
      file.buffer[0] === 0x89 &&
      file.buffer[1] === 0x50 &&
      file.buffer[2] === 0x4e &&
      file.buffer[3] === 0x47;

    const isJpeg =
      file.buffer &&
      file.buffer.length >= 3 &&
      file.buffer[0] === 0xff &&
      file.buffer[1] === 0xd8 &&
      file.buffer[2] === 0xff;

    const isWebp =
      file.buffer &&
      file.buffer.length >= 12 &&
      file.buffer.subarray(0, 4).toString() === 'RIFF' &&
      file.buffer.subarray(8, 12).toString() === 'WEBP';

    const isGif =
      file.buffer &&
      file.buffer.length >= 6 &&
      (file.buffer.subarray(0, 6).toString() === 'GIF87a' ||
        file.buffer.subarray(0, 6).toString() === 'GIF89a');

    const isSvg =
      file.buffer &&
      file.buffer.subarray(0, 100).toString().toLowerCase().includes('<svg');

    const isImageMime = Boolean(file.mimetype?.startsWith('image/'));
    const hasImageExt = Boolean(
      file.originalname?.toLowerCase().match(/\.(png|jpe?g|webp|svg|gif)$/),
    );

    const isImage =
      isPng || isJpeg || isWebp || isGif || isSvg || isImageMime || hasImageExt;

    if (!isImage) {
      throw new BadRequestException(
        'เลือกได้เฉพาะไฟล์รูปภาพเท่านั้น (PNG, JPG, WEBP, SVG)',
      );
    }

    let ext = 'png';
    let mimeType = 'image/png';
    if (isPng) {
      ext = 'png';
      mimeType = 'image/png';
    } else if (isJpeg) {
      ext = 'jpg';
      mimeType = 'image/jpeg';
    } else if (isWebp) {
      ext = 'webp';
      mimeType = 'image/webp';
    } else if (isGif) {
      ext = 'gif';
      mimeType = 'image/gif';
    } else if (isSvg) {
      ext = 'svg';
      mimeType = 'image/svg+xml';
    } else if (file.mimetype && file.mimetype.startsWith('image/')) {
      mimeType = file.mimetype;
      const sub = file.mimetype.split('/')[1];
      ext = sub === 'jpeg' ? 'jpg' : sub;
    } else if (hasImageExt) {
      const match = file.originalname?.toLowerCase().match(/\.([a-z0-9]+)$/);
      if (match) {
        ext = match[1];
        mimeType = ext === 'jpg' ? 'image/jpeg' : `image/${ext}`;
      }
    }

    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    // Clean up old avatar if exists
    if (profile.avatarObjectKey) {
      try {
        await this.storageService.delete(profile.avatarObjectKey);
      } catch {
        // ignore storage delete errors
      }
    }

    const objectKey = `student-avatars/${user.userId}/${Date.now()}-${randomUUID()}.${ext}`;
    await this.storageService.put(objectKey, file.buffer, mimeType);

    const updated = await this.studentsRepository.updateAvatar(
      user.userId,
      objectKey,
    );
    if (!updated) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    return toDto(updated);
  }

  async getAvatarFile(
    user: AuthUser,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    this.assertStudent(user);
    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    if (!profile.avatarObjectKey) {
      throw new NotFoundException('ไม่พบรูปโปรไฟล์');
    }
    const buffer = await this.storageService.get(profile.avatarObjectKey);
    if (!buffer) {
      throw new NotFoundException('ไม่พบรูปโปรไฟล์');
    }
    const ext = profile.avatarObjectKey.split('.').pop()?.toLowerCase();
    let mimeType = 'image/png';
    if (ext === 'jpg' || ext === 'jpeg') mimeType = 'image/jpeg';
    else if (ext === 'webp') mimeType = 'image/webp';
    else if (ext === 'svg') mimeType = 'image/svg+xml';
    else if (ext === 'gif') mimeType = 'image/gif';

    return { buffer, mimeType };
  }

  async deleteAvatar(user: AuthUser): Promise<StudentProfileDto> {
    this.assertStudent(user);
    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    if (profile.avatarObjectKey) {
      try {
        await this.storageService.delete(profile.avatarObjectKey);
      } catch {
        // ignore storage delete errors
      }
    }
    const updated = await this.studentsRepository.updateAvatar(
      user.userId,
      null,
    );
    if (!updated) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    return toDto(updated);
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
  bio?: string | null;
  contactLinks?: Array<{
    id?: string;
    platform: string;
    label?: string;
    value: string;
  }> | null;
  portfolioLinks?: Array<{
    id?: string;
    title: string;
    url: string;
    description?: string;
  }> | null;
  portfolioUrl: string | null;
  resumeFileName?: string | null;
  resumeObjectKey?: string | null;
  avatarObjectKey?: string | null;
}): StudentProfileDto {
  const dto = new StudentProfileDto();
  dto.fullName = profile.fullName;
  dto.university = profile.university;
  dto.major = profile.major;
  dto.skills = profile.skills;
  dto.bio = profile.bio ?? '';
  dto.contactLinks = (profile.contactLinks ?? []).map((c) => ({
    id: c.id,
    platform: c.platform,
    label: c.label,
    value: c.value,
  }));
  dto.portfolioLinks = (profile.portfolioLinks ?? []).map((p) => ({
    id: p.id,
    title: p.title,
    url: p.url,
    description: p.description,
  }));
  dto.portfolioUrl = profile.portfolioUrl;
  dto.resumeFileName = profile.resumeFileName ?? null;
  dto.resumeObjectKey = profile.resumeObjectKey ?? null;
  dto.avatarObjectKey = profile.avatarObjectKey ?? null;
  return dto;
}

