import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '../auth/user-role.js';
import { ProvincesService } from '../provinces/provinces.service.js';
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
  };

  const storageService = {
    put: vi.fn(),
  };
  const provincesService = { requireById: vi.fn() };

  const companyUser = { userId: 'company-user-1', role: UserRole.Company };
  const studentUser = { userId: 'student-user-1', role: UserRole.Student };

  beforeEach(async () => {
    vi.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        CompaniesService,
        { provide: CompaniesRepository, useValue: repository },
        { provide: StorageService, useValue: storageService },
        { provide: ProvincesService, useValue: provincesService },
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
      });

      const result = await service.getProfile(companyUser);

      expect(result).toEqual({
        name: 'Tech Corp',
        businessType: 'Software',
        description: 'Tech Company',
        logoObjectKey: 'company-logos/user-1/logo.png',
        provinceId: null,
        provinceName: null,
        location: '',
        latitude: null,
        longitude: null,
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
      });

      const result = await service.updateProfile(companyUser, {
        name: ' Updated Tech Corp ',
        businessType: ' Consulting ',
        description: ' Updated Description ',
      });

      expect(repository.updateProfile).toHaveBeenCalledWith(
        'company-profile-1',
        {
          name: 'Updated Tech Corp',
          businessType: 'Consulting',
          description: 'Updated Description',
        },
      );
      expect(result).toEqual({
        name: 'Updated Tech Corp',
        businessType: 'Consulting',
        description: 'Updated Description',
        logoObjectKey: null,
        provinceId: null,
        provinceName: null,
        location: '',
        latitude: null,
        longitude: null,
      });
    });

    it('saves a selected province, short address and office pin', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        provinceId: null,
      });
      provincesService.requireById.mockResolvedValue({
        id: 90,
        nameTh: 'สงขลา',
      });
      repository.updateProfile.mockResolvedValue({
        name: 'Tech Corp',
        businessType: 'IT',
        description: '',
        logoObjectKey: null,
        provinceId: 90,
        province: { nameTh: 'สงขลา' },
        location: 'ถนนกาญจนวนิช',
        latitude: 7.0064,
        longitude: 100.5008,
      });

      const result = await service.updateProfile(companyUser, {
        provinceId: 90,
        location: ' ถนนกาญจนวนิช ',
        latitude: 7.0064,
        longitude: 100.5008,
      });

      expect(provincesService.requireById).toHaveBeenCalledWith(90);
      expect(repository.updateProfile).toHaveBeenCalledWith(
        'company-profile-1',
        {
          provinceId: 90,
          location: 'ถนนกาญจนวนิช',
          latitude: 7.0064,
          longitude: 100.5008,
        },
      );
      expect(result).toMatchObject({
        provinceName: 'สงขลา',
        location: 'ถนนกาญจนวนิช',
      });
    });

    it('rejects saving an office pin before a province is selected', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        provinceId: null,
      });

      await expect(
        service.updateProfile(companyUser, { latitude: 7, longitude: 100 }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(repository.updateProfile).not.toHaveBeenCalled();
    });

    it('rejects a partial or out-of-range coordinate pair', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        provinceId: 90,
      });

      await expect(
        service.updateProfile(companyUser, { latitude: 7 }),
      ).rejects.toBeInstanceOf(BadRequestException);
      await expect(
        service.updateProfile(companyUser, { latitude: 91, longitude: 100 }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(repository.updateProfile).not.toHaveBeenCalled();
    });

    it('rejects an address longer than the short-address column', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        provinceId: null,
      });

      await expect(
        service.updateProfile(companyUser, { location: 'ก'.repeat(256) }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(repository.updateProfile).not.toHaveBeenCalled();
    });

    it('clears the old pin when province changes without a new pin', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        provinceId: 10,
        latitude: 13.75,
        longitude: 100.5,
      });
      provincesService.requireById.mockResolvedValue({
        id: 90,
        nameTh: 'สงขลา',
      });
      repository.updateProfile.mockResolvedValue({
        name: 'Tech Corp',
        businessType: 'IT',
        description: '',
        logoObjectKey: null,
        provinceId: 90,
        province: { nameTh: 'สงขลา' },
        location: '',
        latitude: null,
        longitude: null,
      });

      await service.updateProfile(companyUser, { provinceId: 90 });

      expect(repository.updateProfile).toHaveBeenCalledWith(
        'company-profile-1',
        {
          provinceId: 90,
          latitude: null,
          longitude: null,
        },
      );
    });

    it('rejects a province ID not in the 77-province master', async () => {
      repository.findCompanyProfileByUserId.mockResolvedValue({
        id: 'company-profile-1',
        provinceId: null,
      });
      provincesService.requireById.mockRejectedValue(
        new BadRequestException('ไม่พบจังหวัดที่เลือก'),
      );

      await expect(
        service.updateProfile(companyUser, { provinceId: 999 }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(repository.updateProfile).not.toHaveBeenCalled();
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
      });
      storageService.put.mockResolvedValue('uploaded-key');
      repository.updateLogoObjectKey.mockResolvedValue({
        id: 'company-profile-1',
        userId: 'company-user-1',
        name: 'Tech Corp',
        businessType: 'IT',
        description: 'Desc',
        logoObjectKey: 'company-logos/company-user-1/mock.png',
      });

      const pngHeader = Buffer.from([
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
      ]);
      const file = {
        fieldname: 'file',
        originalname: 'logo.png',
        encoding: '7bit',
        mimetype: 'image/png',
        size: 8,
        buffer: pngHeader,
      };

      const result = await service.uploadLogo(companyUser, file);

      expect(storageService.put).toHaveBeenCalledWith(
        expect.stringMatching(/^company-logos\/company-user-1\/.+\.png$/),
        pngHeader,
        'image/png',
      );
      expect(repository.updateLogoObjectKey).toHaveBeenCalled();
      expect(result).toEqual({
        name: 'Tech Corp',
        businessType: 'IT',
        description: 'Desc',
        logoObjectKey: 'company-logos/company-user-1/mock.png',
        provinceId: null,
        provinceName: null,
        location: '',
        latitude: null,
        longitude: null,
      });
    });

    it('throws BadRequestException when file is missing', async () => {
      await expect(
        service.uploadLogo(companyUser, undefined),
      ).rejects.toBeInstanceOf(BadRequestException);
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

      await expect(
        service.uploadLogo(companyUser, file),
      ).rejects.toBeInstanceOf(BadRequestException);
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

      await expect(
        service.uploadLogo(studentUser, file),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });
});
