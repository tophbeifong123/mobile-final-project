import { randomUUID } from 'node:crypto';
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { type AuthUser } from '../auth/auth-user.js';
import { type StudentProfile } from '../auth/entities/student-profile.entity.js';
import { UserRole } from '../auth/user-role.js';
import { StorageService } from '../storage/storage.service.js';
import { type UploadedFilePayload } from '../storage/uploaded-file.interface.js';
import { UniversitiesService } from '../universities/universities.service.js';
import { ResumeResponseDto } from './dto/resume-response.dto.js';
import { StudentProfileDto } from './dto/student-profile.dto.js';
import { UpdateStudentProfileDto } from './dto/update-student-profile.dto.js';
import { StudentDocumentType } from './student-document.entity.js';
import {
  StudentsRepository,
  TooManyOtherDocumentsError,
} from './students.repository.js';

const STUDENT_ONLY = 'เฉพาะนักศึกษาเท่านั้น';
const PROFILE_NOT_FOUND = 'ไม่พบโปรไฟล์';
const ONLY_PDF_ALLOWED = 'เลือกได้เฉพาะไฟล์ PDF เท่านั้น';
const FILE_REQUIRED = 'กรุณาเลือกไฟล์ PDF';
const RESUME_NOT_FOUND = 'ไม่พบไฟล์ Resume';
const MAX_DOCUMENT_BYTES = 10 * 1024 * 1024;

function sanitizePdfName(name?: string): string {
  const cleaned = (name ?? 'document.pdf').replace(/[\\/\r\n"]/g, '_').trim();
  const bounded = cleaned.slice(0, 250) || 'document';
  return bounded.toLowerCase().endsWith('.pdf')
    ? bounded
    : `${bounded}.pdf`;
}

@Injectable()
export class StudentsService {
  constructor(
    private readonly studentsRepository: StudentsRepository,
    private readonly storageService: StorageService,
    private readonly universitiesService: UniversitiesService,
  ) {}

  async getMine(user: AuthUser): Promise<StudentProfileDto> {
    this.assertStudent(user);
    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    return this.toProfileDto(profile);
  }

  async updateMine(
    user: AuthUser,
    dto: UpdateStudentProfileDto,
  ): Promise<StudentProfileDto> {
    this.assertStudent(user);

    let universityId: string | null | undefined;
    let customUniversityName: string | null | undefined;

    if (
      dto.universityId !== undefined ||
      dto.customUniversityName !== undefined
    ) {
      const custom = dto.customUniversityName?.trim() || null;
      if (dto.universityId != null && custom != null) {
        throw new BadRequestException(
          'เลือกมหาวิทยาลัยจากรายการหรือกรอกชื่อเองได้อย่างใดอย่างหนึ่ง',
        );
      }
      universityId = dto.universityId ?? null;
      customUniversityName = universityId ? null : custom;
      if (universityId) {
        await this.universitiesService.requireById(universityId);
      }
    }

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
      universityId,
      customUniversityName,
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
    return this.toProfileDto(saved);
  }

  async uploadResume(
    user: AuthUser,
    file: UploadedFilePayload | undefined,
  ): Promise<ResumeResponseDto> {
    const document = await this.uploadDocument(
      user,
      StudentDocumentType.Cv,
      file,
    );
    return {
      fileName: document.fileName,
      objectKey: document.objectKey,
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

    const cv = await this.studentsRepository.findCv(profile.id);
    if (cv) {
      const currentBuffer = await this.storageService.get(cv.objectKey);
      if (!currentBuffer) {
        throw new NotFoundException(RESUME_NOT_FOUND);
      }
      return { buffer: currentBuffer, fileName: cv.fileName };
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

  async listDocuments(user: AuthUser) {
    this.assertStudent(user);
    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }
    return this.studentsRepository.listDocuments(profile.id);
  }

  async uploadDocument(
    user: AuthUser,
    type: StudentDocumentType,
    file?: UploadedFilePayload,
  ) {
    this.assertStudent(user);

    if (!file) {
      throw new BadRequestException(FILE_REQUIRED);
    }
    if (
      !file.buffer?.length ||
      file.buffer.length > MAX_DOCUMENT_BYTES ||
      file.buffer.subarray(0, 5).toString() !== '%PDF-'
    ) {
      throw new BadRequestException(ONLY_PDF_ALLOWED);
    }

    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    const fileName = sanitizePdfName(file.originalname);
    const objectKey =
      `student-documents/${user.userId}/${type}/${randomUUID()}.pdf`;

    await this.storageService.put(objectKey, file.buffer, 'application/pdf');

    try {
      const { document, replacedDocument } =
        await this.studentsRepository.saveDocument({
          studentId: profile.id,
          type,
          objectKey,
          fileName,
        });

      if (
        replacedDocument &&
        !(await this.studentsRepository.isObjectReferencedByApplication(
          replacedDocument.objectKey,
        ))
      ) {
        await this.storageService
          .delete(replacedDocument.objectKey)
          .catch(() => undefined);
      }

      return document;
    } catch (error) {
      await this.storageService.delete(objectKey).catch(() => undefined);
      if (error instanceof TooManyOtherDocumentsError) {
        throw new BadRequestException('เพิ่มเอกสารอื่นได้ไม่เกิน 3 ไฟล์');
      }
      throw error;
    }
  }

  async deleteDocument(user: AuthUser, id: string): Promise<void> {
    this.assertStudent(user);
    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    const document = await this.studentsRepository.deleteDocument(
      profile.id,
      id,
    );
    if (!document) {
      throw new NotFoundException('ไม่พบเอกสาร');
    }

    if (
      !(await this.studentsRepository.isObjectReferencedByApplication(
        document.objectKey,
      ))
    ) {
      await this.storageService.delete(document.objectKey).catch(() => undefined);
    }
  }

  async getStudentDocument(
    user: AuthUser,
    id: string,
  ): Promise<{ buffer: Buffer; fileName: string }> {
    this.assertStudent(user);
    const profile = await this.studentsRepository.findByUserId(user.userId);
    if (!profile) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    const document = await this.studentsRepository.findDocument(profile.id, id);
    if (!document) {
      throw new NotFoundException('ไม่พบเอกสาร');
    }

    const buffer = await this.storageService.get(document.objectKey);
    if (!buffer) {
      throw new NotFoundException('ไม่พบไฟล์เอกสาร');
    }

    return { buffer, fileName: document.fileName };
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

    if (
      !(
        isPng ||
        isJpeg ||
        isWebp ||
        isGif ||
        isSvg ||
        isImageMime ||
        hasImageExt
      )
    ) {
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
    } else if (file.mimetype?.startsWith('image/')) {
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

    if (profile.avatarObjectKey) {
      try {
        await this.storageService.delete(profile.avatarObjectKey);
      } catch {
        // Ignore old-avatar cleanup failures.
      }
    }

    const objectKey =
      `student-avatars/${user.userId}/${Date.now()}-${randomUUID()}.${ext}`;

    await this.storageService.put(objectKey, file.buffer, mimeType);

    const updated = await this.studentsRepository.updateAvatar(
      user.userId,
      objectKey,
    );
    if (!updated) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    return this.toProfileDto(updated);
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

    if (ext === 'jpg' || ext === 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (ext === 'webp') {
      mimeType = 'image/webp';
    } else if (ext === 'svg') {
      mimeType = 'image/svg+xml';
    } else if (ext === 'gif') {
      mimeType = 'image/gif';
    }

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
        // Ignore old-avatar cleanup failures.
      }
    }

    const updated = await this.studentsRepository.updateAvatar(
      user.userId,
      null,
    );
    if (!updated) {
      throw new NotFoundException(PROFILE_NOT_FOUND);
    }

    return this.toProfileDto(updated);
  }

  private assertStudent(user: AuthUser): void {
    if (user.role !== UserRole.Student) {
      throw new ForbiddenException(STUDENT_ONLY);
    }
  }

  private async toProfileDto(
    profile: StudentProfile,
  ): Promise<StudentProfileDto> {
    const dto = toDto(
      profile,
      await this.studentsRepository.resolveDisplayUniversity(profile),
    );

    const cv = await this.studentsRepository.findCv(profile.id);
    dto.resumeFileName = cv?.fileName ?? profile.resumeFileName ?? null;
    dto.resumeObjectKey = cv?.objectKey ?? profile.resumeObjectKey ?? null;

    return dto;
  }
}

function toDto(
  profile: {
    id?: string;
    universityId?: string | null;
    customUniversityName?: string | null;
    fullName: string;
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
  },
  university = '',
): StudentProfileDto {
  const dto = new StudentProfileDto();

  dto.fullName = profile.fullName.trim();
  dto.universityId = profile.universityId ?? null;
  dto.customUniversityName = profile.customUniversityName ?? null;
  dto.university = university.trim();
  dto.major = profile.major;
  dto.skills = profile.skills;
  dto.bio = profile.bio ?? '';
  dto.contactLinks = (profile.contactLinks ?? []).map((contact) => ({
    id: contact.id,
    platform: contact.platform,
    label: contact.label,
    value: contact.value,
  }));
  dto.portfolioLinks = (profile.portfolioLinks ?? []).map((portfolio) => ({
    id: portfolio.id,
    title: portfolio.title,
    url: portfolio.url,
    description: portfolio.description,
  }));
  dto.portfolioUrl = profile.portfolioUrl;
  dto.resumeFileName = profile.resumeFileName ?? null;
  dto.resumeObjectKey = profile.resumeObjectKey ?? null;
  dto.avatarObjectKey = profile.avatarObjectKey ?? null;

  return dto;
}