import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '../auth/user-role.js';
import { CreateJobDto } from './dto/create-job.dto.js';
import { JobStatus, WorkMode } from './job-enums.js';
import { JobsRepository } from './jobs.repository.js';
import { JobsService } from './jobs.service.js';

describe('JobsService', () => {
  const repository = {
    findCompanyId: vi.fn(),
    create: vi.fn(),
  };

  let service: JobsService;

  const company = { userId: 'user-1', role: UserRole.Company };
  const student = { userId: 'user-2', role: UserRole.Student };

  beforeEach(async () => {
    vi.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        JobsService,
        { provide: JobsRepository, useValue: repository },
      ],
    }).compile();
    service = module.get(JobsService);
  });

  it('creates an open job for the signed-in company', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.create.mockResolvedValue({
      id: 'job-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.Hybrid,
      category: 'IT',
      hasAllowance: true,
      requirements: 'ใช้ Flutter ได้',
      status: JobStatus.Open,
      version: 1,
    });
    const dto = new CreateJobDto();
    dto.title = '  Flutter Intern  ';
    dto.description = ' ช่วยพัฒนาแอป ';
    dto.province = ' สงขลา ';
    dto.workMode = WorkMode.Hybrid;
    dto.category = ' IT ';
    dto.hasAllowance = true;
    dto.requirements = ' ใช้ Flutter ได้ ';

    const result = await service.create(company, dto);

    expect(repository.create).toHaveBeenCalledWith({
      companyId: 'company-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.Hybrid,
      category: 'IT',
      hasAllowance: true,
      requirements: 'ใช้ Flutter ได้',
    });
    expect(result.status).toBe(JobStatus.Open);
    expect(result.version).toBe(1);
  });

  it('rejects a student creating a job', async () => {
    const dto = new CreateJobDto();
    dto.title = 'งาน';
    dto.description = 'รายละเอียด';
    dto.province = 'สงขลา';
    dto.workMode = WorkMode.Remote;
    dto.category = 'IT';
    dto.hasAllowance = false;
    dto.requirements = 'คุณสมบัติ';

    await expect(service.create(student, dto)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.findCompanyId).not.toHaveBeenCalled();
  });

  it('returns not found when the company profile row is missing', async () => {
    repository.findCompanyId.mockResolvedValue(null);
    const dto = new CreateJobDto();
    dto.title = 'งาน';
    dto.description = 'รายละเอียด';
    dto.province = 'สงขลา';
    dto.workMode = WorkMode.OnSite;
    dto.category = 'IT';
    dto.hasAllowance = false;
    dto.requirements = 'คุณสมบัติ';

    await expect(service.create(company, dto)).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(repository.create).not.toHaveBeenCalled();
  });
});
