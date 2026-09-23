import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '../auth/user-role.js';
import { CompaniesRepository } from './companies.repository.js';
import { CompaniesService } from './companies.service.js';

describe('CompaniesService', () => {
  let service: CompaniesService;

  const repository = {
    findCompanyProfileByUserId: vi.fn(),
    getDashboardSummary: vi.fn(),
  };

  const companyUser = { userId: 'company-user-1', role: UserRole.Company };
  const studentUser = { userId: 'student-user-1', role: UserRole.Student };

  beforeEach(async () => {
    vi.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        CompaniesService,
        { provide: CompaniesRepository, useValue: repository },
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
});
