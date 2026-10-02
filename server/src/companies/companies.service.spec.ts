import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '../auth/user-role.js';
import { StorageService } from '../storage/storage.service.js';
import { CompaniesRepository } from './companies.repository.js';
import { CompaniesService } from './companies.service.js';

describe('CompaniesService', () => {
  let service: CompaniesService;

  const repository = {
    findCompanyProfileByUserId: vi.fn(),
    getDashboardSummary: vi.fn(),
    updateProfile: vi.fn(),
    updateLogoObjectKey: vi.fn(),
    updateCoverObjectKey: vi.fn(),
  };

  const storageService = {
    put: vi.fn(),
    get: vi.fn(),
    delete: vi.fn(),
  };

  const companyUser = { userId: 'company-user-1', role: UserRole.Company };
  const studentUser = { userId: 'student-user-1', role: UserRole.Student };

  beforeEach(async () => {
    vi.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        CompaniesService,
        { provide: CompaniesRepository, useValue: repository },
        { provide: StorageService, useValue: storageService },
      ],
    }).compile();

    service = module.get(CompaniesService);
  });

  describe('getDashboard', () => {
    it('returns dashboard summary for company', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        name: 'Tech Corp',
      });
      repository.getDashboardSummary.mockResolvedValue({
        totalJobs: 5,
        openJobs: 3,
        totalApplicants: 12,
      });

      const result = await service.getDashboard(companyUser);

      expect(repository.findCompanyProfileByUserId).toHaveBeenCalledWith(
        'company-user-1',
      );
      expect(repository.getDashboardSummary).toHaveBeenCalledWith(
        'company-profile-1',
      );
      expect(result).toEqual({
        totalJobs: 5,
        openJobs: 3,
        totalApplicants: 12,
      });
    });

    it('returns 0 applicants when company has no applicants', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        name: 'Tech Corp',
      });
      repository.getDashboardSummary.mockResolvedValue({
        totalJobs: 1,
        openJobs: 1,
        totalApplicants: 0,
      });

      const result = await service.getDashboard(companyUser);

      expect(result.totalApplicants).toBe(0);
    });

    it('rejects student accessing company dashboard', async () => {
      await expect(service.getDashboard(studentUser)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(repository.findCompanyProfileByUserId).not.toHaveBeenCalled();
    });

    it('throws NotFoundException if company profile is missing', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue(null);

      await expect(service.getDashboard(companyUser)).rejects.toBeInstanceOf(
        NotFoundException,
      );
      expect(repository.getDashboardSummary).not.toHaveBeenCalled();
    });
  });

  describe('getProfile', () => {
    it('returns company profile for company user', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        name: 'Tech Corp',
        businessType: 'Software',
        description: 'Tech Company',
        logoObjectKey: 'company-logos/user-1/logo.png',
        websiteUrl: 'https://example.com',
        location: 'Bangkok',
        companySize: '51-200 คน',
        perks: ['Free Lunch'],
        coverObjectKey: 'company-covers/user-1/cover.jpg',
      });

      const result = await service.getProfile(companyUser);

      expect(result).toEqual({
        name: 'Tech Corp',
        businessType: 'Software',
        description: 'Tech Company',
        logoObjectKey: 'company-logos/user-1/logo.png',
        websiteUrl: 'https://example.com',
        location: 'Bangkok',
        companySize: '51-200 คน',
        perks: ['Free Lunch'],
        coverObjectKey: 'company-covers/user-1/cover.jpg',
      });
    });

    it('rejects student accessing company profile', async () => {
      await expect(service.getProfile(studentUser)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('throws NotFoundException when company profile is not found', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue(null);

      await expect(service.getProfile(companyUser)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('updateProfile', () => {
    it('updates company profile fields and returns updated DTO', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
      });
      repository.updateProfile.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        name: 'Updated Tech Corp',
        businessType: 'Consulting',
        description: 'Updated Description',
        logoObjectKey: null,
        websiteUrl: 'https://updated.com',
        location: 'FYI Center',
        companySize: '201-500 คน',
        perks: ['MacBook'],
        coverObjectKey: null,
      });

      const result = await service.updateProfile(companyUser, {
        name: ' Updated Tech Corp ',
        businessType: ' Consulting ',
        description: ' Updated Description ',
        websiteUrl: ' https://updated.com ',
        location: ' FYI Center ',
        companySize: ' 201-500 คน ',
        perks: ['MacBook'],
      });

      expect(repository.updateProfile).toHaveBeenCalledWith(
        'company-profile-1',
        {
          name: 'Updated Tech Corp',
          businessType: 'Consulting',
          description: 'Updated Description',
          websiteUrl: 'https://updated.com',
          location: 'FYI Center',
          companySize: '201-500 คน',
          perks: ['MacBook'],
        },
      );
      expect(result).toEqual({
        name: 'Updated Tech Corp',
        businessType: 'Consulting',
        description: 'Updated Description',
        logoObjectKey: null,
        websiteUrl: 'https://updated.com',
        location: 'FYI Center',
        companySize: '201-500 คน',
        perks: ['MacBook'],
        coverObjectKey: null,
      });
    });

    it('rejects student updating company profile', async () => {
      await expect(
        service.updateProfile(studentUser, {
          name: 'Tech',
          businessType: 'IT',
          description: 'Desc',
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('throws NotFoundException if profile does not exist', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue(null);

      await expect(
        service.updateProfile(companyUser, {
          name: 'Tech',
          businessType: 'IT',
          description: 'Desc',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('uploadLogo', () => {
    it('uploads valid image file and updates company profile', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        logoObjectKey: 'company-logos/company-user-1/old.png',
      });
      storageService.put.mockResolvedValue('uploaded-key');
      repository.updateLogoObjectKey.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        name: 'Tech Corp',
        businessType: 'IT',
        description: 'Desc',
        logoObjectKey: 'company-logos/company-user-1/mock.png',
        websiteUrl: '',
        location: '',
        companySize: '',
        perks: [],
        coverObjectKey: null,
      });

      const pngHeader = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
      const file = {
        fieldname: 'file',
        originalname: 'logo.png',
        encoding: '7bit',
        mimetype: 'image/png',
        size: 8,
        buffer: pngHeader,
      };

      const result = await service.uploadLogo(companyUser, file);

      expect(storageService.delete).toHaveBeenCalledWith(
        'company-logos/company-user-1/old.png',
      );
      expect(storageService.put).toHaveBeenCalledWith(
        expect.stringMatching(/^company-logos\/company-user-1\/.+\.png$/),
        pngHeader,
        'image/png',
      );
      expect(repository.updateLogoObjectKey).toHaveBeenCalled();
      expect(result.logoObjectKey).toBe('company-logos/company-user-1/mock.png');
    });

    it('throws BadRequestException when file is missing', async () => {
      await expect(service.uploadLogo(companyUser, undefined)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('throws BadRequestException when file is not an image', async () => {
      const pdfHeader = Buffer.from('%PDF-1.5');
      const file = {
        fieldname: 'file',
        originalname: 'document.pdf',
        encoding: '7bit',
        mimetype: 'application/pdf',
        size: 8,
        buffer: pdfHeader,
      };

      await expect(service.uploadLogo(companyUser, file)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('rejects student uploading company logo', async () => {
      const file = {
        fieldname: 'file',
        originalname: 'logo.png',
        encoding: '7bit',
        mimetype: 'image/png',
        size: 8,
        buffer: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      };

      await expect(service.uploadLogo(studentUser, file)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });
  });

  describe('getLogoFile', () => {
    it('returns buffer and mimeType', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        logoObjectKey: 'company-logos/user/test.png',
      });
      const dummyBuffer = Buffer.from('logo-bytes');
      storageService.get.mockResolvedValue(dummyBuffer);

      const result = await service.getLogoFile(companyUser);
      expect(result).toEqual({ buffer: dummyBuffer, mimeType: 'image/png' });
    });

    it('throws NotFoundException if no logo exists', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        logoObjectKey: null,
      });

      await expect(service.getLogoFile(companyUser)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('deleteLogo', () => {
    it('deletes logo and updates profile', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        logoObjectKey: 'company-logos/user/test.png',
      });
      repository.updateLogoObjectKey.mockResolvedValue({
        name: 'Tech Corp',
        businessType: 'Software',
        description: 'Desc',
        logoObjectKey: null,
        websiteUrl: '',
        location: '',
        companySize: '',
        perks: [],
        coverObjectKey: null,
      });

      const result = await service.deleteLogo(companyUser);
      expect(storageService.delete).toHaveBeenCalledWith('company-logos/user/test.png');
      expect(repository.updateLogoObjectKey).toHaveBeenCalledWith('company-profile-1', null);
      expect(result.logoObjectKey).toBeNull();
    });
  });

  describe('uploadCover & deleteCover', () => {
    it('uploads valid cover image', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        coverObjectKey: null,
      });
      storageService.put.mockResolvedValue('uploaded-key');
      repository.updateCoverObjectKey.mockResolvedValue({
        name: 'Tech Corp',
        businessType: 'IT',
        description: 'Desc',
        logoObjectKey: null,
        websiteUrl: '',
        location: '',
        companySize: '',
        perks: [],
        coverObjectKey: 'company-covers/company-user-1/mock.jpg',
      });

      const jpegHeader = Buffer.from([0xff, 0xd8, 0xff, 0xe0]);
      const file = {
        fieldname: 'file',
        originalname: 'cover.jpg',
        encoding: '7bit',
        mimetype: 'image/jpeg',
        size: 4,
        buffer: jpegHeader,
      };

      const result = await service.uploadCover(companyUser, file);
      expect(storageService.put).toHaveBeenCalled();
      expect(repository.updateCoverObjectKey).toHaveBeenCalled();
      expect(result.coverObjectKey).toBe('company-covers/company-user-1/mock.jpg');
    });

    it('gets cover file and returns buffer and mimeType', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        coverObjectKey: 'company-covers/user/test.webp',
      });
      const dummyBuffer = Buffer.from('cover-bytes');
      storageService.get.mockResolvedValue(dummyBuffer);

      const result = await service.getCoverFile(companyUser);
      expect(result).toEqual({ buffer: dummyBuffer, mimeType: 'image/webp' });
    });

    it('deletes cover file', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        coverObjectKey: 'company-covers/user/test.jpg',
      });
      repository.updateCoverObjectKey.mockResolvedValue({
        name: 'Tech Corp',
        businessType: 'Software',
        description: 'Desc',
        logoObjectKey: null,
        websiteUrl: '',
        location: '',
        companySize: '',
        perks: [],
        coverObjectKey: null,
      });

      const result = await service.deleteCover(companyUser);
      expect(storageService.delete).toHaveBeenCalledWith('company-covers/user/test.jpg');
      expect(repository.updateCoverObjectKey).toHaveBeenCalledWith('company-profile-1', null);
      expect(result.coverObjectKey).toBeNull();
    });
  });
});
