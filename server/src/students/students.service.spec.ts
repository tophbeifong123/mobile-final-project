import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '../auth/user-role.js';
import { StorageService } from '../storage/storage.service.js';
import { type UploadedFilePayload } from '../storage/uploaded-file.interface.js';
import { UpdateStudentProfileDto } from './dto/update-student-profile.dto.js';
import { StudentsRepository } from './students.repository.js';
import { StudentsService } from './students.service.js';

describe('StudentsService', () => {
  const repository = {
    findByUserId: vi.fn(),
    updateByUserId: vi.fn(),
    updateResume: vi.fn(),
    updateAvatar: vi.fn(),
  };

  const storage = {
    put: vi.fn(),
    get: vi.fn(),
    delete: vi.fn(),
  };

  let service: StudentsService;

  const student = { userId: 'user-1', role: UserRole.Student };
  const company = { userId: 'user-2', role: UserRole.Company };
  const stored = {
    fullName: 'มีนา',
    university: 'PSU',
    major: 'IT',
    skills: ['Flutter'],
    portfolioUrl: null,
    resumeFileName: 'resume.pdf',
    resumeObjectKey: 'resumes/user-1/123.pdf',
  };

  beforeEach(async () => {
    vi.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        StudentsService,
        { provide: StudentsRepository, useValue: repository },
        { provide: StorageService, useValue: storage },
      ],
    }).compile();
    service = module.get(StudentsService);
  });

  it('returns the signed-in student profile including resume fields', async () => {
    repository.findByUserId.mockResolvedValue(stored);

    const result = await service.getMine(student);

    expect(repository.findByUserId).toHaveBeenCalledWith('user-1');
    expect(result).toMatchObject(stored);
    expect(result.resumeFileName).toBe('resume.pdf');
    expect(result.resumeObjectKey).toBe('resumes/user-1/123.pdf');
  });

  it('rejects a company reading a student profile', async () => {
    await expect(service.getMine(company)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.findByUserId).not.toHaveBeenCalled();
  });

  it('returns not found when the student has no profile row', async () => {
    repository.findByUserId.mockResolvedValue(null);

    await expect(service.getMine(student)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('saves trimmed profile fields and clears a blank portfolio', async () => {
    repository.updateByUserId.mockResolvedValue({
      fullName: 'มีนา',
      university: 'PSU',
      major: 'IT',
      skills: ['Flutter', 'SQL'],
      portfolioUrl: null,
    });
    const dto = new UpdateStudentProfileDto();
    dto.fullName = '  มีนา  ';
    dto.university = ' PSU ';
    dto.major = ' IT ';
    dto.skills = [' Flutter ', '', 'SQL'];
    dto.portfolioUrl = '   ';

    const result = await service.updateMine(student, dto);

    expect(repository.updateByUserId).toHaveBeenCalledWith('user-1', {
      fullName: 'มีนา',
      university: 'PSU',
      major: 'IT',
      skills: ['Flutter', 'SQL'],
      portfolioUrl: null,
    });
    expect(result.portfolioUrl).toBeNull();
    expect(result.skills).toEqual(['Flutter', 'SQL']);
  });

  it('rejects a company updating a student profile', async () => {
    const dto = new UpdateStudentProfileDto();
    dto.fullName = 'บริษัท';
    dto.university = 'PSU';
    dto.major = 'IT';
    dto.skills = [];

    await expect(service.updateMine(company, dto)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.updateByUserId).not.toHaveBeenCalled();
  });

  describe('uploadResume', () => {
    const validPdfFile: UploadedFilePayload = {
      fieldname: 'file',
      originalname: 'my-resume.pdf',
      encoding: '7bit',
      mimetype: 'application/pdf',
      size: 1024,
      buffer: Buffer.from('%PDF-1.4 test resume content'),
    };

    it('uploads a valid PDF resume and updates the student profile', async () => {
      repository.findByUserId.mockResolvedValue(stored);
      storage.put.mockResolvedValue('resumes/user-1/generated-key.pdf');
      repository.updateResume.mockResolvedValue({
        ...stored,
        resumeFileName: 'my-resume.pdf',
        resumeObjectKey: 'resumes/user-1/generated-key.pdf',
      });

      const result = await service.uploadResume(student, validPdfFile);

      expect(storage.put).toHaveBeenCalledWith(
        expect.stringMatching(/^resumes\/user-1\/.+\.pdf$/),
        validPdfFile.buffer,
        'application/pdf',
      );
      expect(repository.updateResume).toHaveBeenCalledWith(
        'user-1',
        expect.stringMatching(/^resumes\/user-1\/.+\.pdf$/),
        'my-resume.pdf',
      );
      expect(result).toEqual({
        fileName: 'my-resume.pdf',
        objectKey: 'resumes/user-1/generated-key.pdf',
      });
    });

    it('rejects a company uploading a resume', async () => {
      await expect(
        service.uploadResume(company, validPdfFile),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(storage.put).not.toHaveBeenCalled();
    });

    it('rejects when no file is provided', async () => {
      await expect(
        service.uploadResume(student, undefined),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects non-PDF files', async () => {
      const pngFile: UploadedFilePayload = {
        fieldname: 'file',
        originalname: 'photo.png',
        encoding: '7bit',
        mimetype: 'image/png',
        size: 1024,
        buffer: Buffer.from('png data'),
      };

      await expect(
        service.uploadResume(student, pngFile),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(storage.put).not.toHaveBeenCalled();
    });

    it('throws not found if profile row does not exist', async () => {
      repository.findByUserId.mockResolvedValue(null);

      await expect(
        service.uploadResume(student, validPdfFile),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(storage.put).not.toHaveBeenCalled();
    });
  });

  describe('getResumeFile', () => {
    it('returns buffer and fileName for student with uploaded resume', async () => {
      repository.findByUserId.mockResolvedValue(stored);
      const pdfBuffer = Buffer.from('%PDF-1.4 sample content');
      storage.get.mockResolvedValue(pdfBuffer);

      const result = await service.getResumeFile(student);

      expect(result.buffer).toBe(pdfBuffer);
      expect(result.fileName).toBe('resume.pdf');
      expect(storage.get).toHaveBeenCalledWith('resumes/user-1/123.pdf');
    });

    it('throws NotFoundException if student has not uploaded a resume', async () => {
      repository.findByUserId.mockResolvedValue({
        ...stored,
        resumeObjectKey: null,
        resumeFileName: null,
      });

      await expect(service.getResumeFile(student)).rejects.toBeInstanceOf(
        NotFoundException,
      );
      expect(storage.get).not.toHaveBeenCalled();
    });

    it('throws NotFoundException if resume file is not found in storage', async () => {
      repository.findByUserId.mockResolvedValue(stored);
      storage.get.mockResolvedValue(null);

      await expect(service.getResumeFile(student)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('rejects a company attempting to get student resume', async () => {
      await expect(service.getResumeFile(company)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });
  });

  describe('uploadAvatar', () => {
    const validPngFile: UploadedFilePayload = {
      buffer: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      originalname: 'profile.png',
      mimetype: 'image/png',
      size: 8,
    };

    it('rejects a company uploading avatar', async () => {
      await expect(service.uploadAvatar(company, validPngFile)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects upload if file is missing', async () => {
      await expect(service.uploadAvatar(student, undefined)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('rejects non-image files', async () => {
      const textFile: UploadedFilePayload = {
        buffer: Buffer.from('hello world'),
        originalname: 'doc.txt',
        mimetype: 'text/plain',
        size: 11,
      };
      await expect(service.uploadAvatar(student, textFile)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('uploads valid image, replaces old avatar, and returns updated profile', async () => {
      repository.findByUserId.mockResolvedValue({
        ...stored,
        avatarObjectKey: 'student-avatars/user-1/old.png',
      });
      storage.put.mockResolvedValue(undefined);
      storage.delete.mockResolvedValue(undefined);
      repository.updateAvatar.mockImplementation((_, key) =>
        Promise.resolve({
          ...stored,
          avatarObjectKey: key,
        }),
      );

      const result = await service.uploadAvatar(student, validPngFile);

      expect(storage.delete).toHaveBeenCalledWith('student-avatars/user-1/old.png');
      expect(storage.put).toHaveBeenCalledWith(
        expect.stringContaining('student-avatars/user-1/'),
        validPngFile.buffer,
        'image/png',
      );
      expect(repository.updateAvatar).toHaveBeenCalled();
      expect(result.avatarObjectKey).toContain('student-avatars/user-1/');
    });
  });

  describe('getAvatarFile', () => {
    it('returns buffer and mimeType when avatar exists', async () => {
      repository.findByUserId.mockResolvedValue({
        ...stored,
        avatarObjectKey: 'student-avatars/user-1/pic.png',
      });
      const imgBuffer = Buffer.from('fake image');
      storage.get.mockResolvedValue(imgBuffer);

      const result = await service.getAvatarFile(student);

      expect(result.buffer).toBe(imgBuffer);
      expect(result.mimeType).toBe('image/png');
    });

    it('throws NotFoundException if student has no avatar', async () => {
      repository.findByUserId.mockResolvedValue({
        ...stored,
        avatarObjectKey: null,
      });

      await expect(service.getAvatarFile(student)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('throws NotFoundException if file is not in storage', async () => {
      repository.findByUserId.mockResolvedValue({
        ...stored,
        avatarObjectKey: 'student-avatars/user-1/pic.png',
      });
      storage.get.mockResolvedValue(null);

      await expect(service.getAvatarFile(student)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('deleteAvatar', () => {
    it('deletes avatar from storage and sets avatar to null', async () => {
      repository.findByUserId.mockResolvedValue({
        ...stored,
        avatarObjectKey: 'student-avatars/user-1/pic.png',
      });
      storage.delete.mockResolvedValue(undefined);
      repository.updateAvatar.mockResolvedValue({
        ...stored,
        avatarObjectKey: null,
      });

      const result = await service.deleteAvatar(student);

      expect(storage.delete).toHaveBeenCalledWith('student-avatars/user-1/pic.png');
      expect(repository.updateAvatar).toHaveBeenCalledWith('user-1', null);
      expect(result.avatarObjectKey).toBeNull();
    });

    it('rejects company', async () => {
      await expect(service.deleteAvatar(company)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });
  });
});
