import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '../auth/user-role.js';
import { CreateJobDto } from './dto/create-job.dto.js';
import { JobFeedQueryDto } from './dto/job-feed-query.dto.js';
import { JobStatus, WorkMode } from './job-enums.js';
import { JobsRepository } from './jobs.repository.js';
import { JobsService } from './jobs.service.js';

describe('JobsService', () => {
  const repository = {
    findCompanyId: vi.fn(),
    findStudentId: vi.fn(),
    create: vi.fn(),
    findOpen: vi.fn(),
    findOpenById: vi.fn(),
    isSaved: vi.fn(),
    save: vi.fn(),
    unsave: vi.fn(),
    listSaved: vi.fn(),
    listByCompany: vi.fn(),
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

  it('returns only the open jobs the repository finds for a student', async () => {
    repository.findOpen.mockResolvedValue([
      {
        id: 'job-1',
        title: 'Flutter Intern',
        companyName: 'InternFinder',
        province: 'สงขลา',
        workMode: WorkMode.Hybrid,
        category: 'IT',
        hasAllowance: true,
        status: JobStatus.Open,
      },
    ]);
    const query = new JobFeedQueryDto();
    query.search = 'flutter';
    query.province = 'สงขลา';
    query.workMode = WorkMode.Hybrid;
    query.category = 'IT';
    query.hasAllowance = true;

    const result = await service.listOpen(student, query);

    expect(repository.findOpen).toHaveBeenCalledWith({
      search: 'flutter',
      province: 'สงขลา',
      workMode: WorkMode.Hybrid,
      category: 'IT',
      hasAllowance: true,
    });
    expect(result).toHaveLength(1);
    expect(result[0]?.status).toBe(JobStatus.Open);
    expect(result[0]?.companyName).toBe('InternFinder');
  });

  it('rejects a company reading the student feed', async () => {
    await expect(
      service.listOpen(company, new JobFeedQueryDto()),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(repository.findOpen).not.toHaveBeenCalled();
  });

  it('returns an open job with the company profile for a student', async () => {
    repository.findOpenById.mockResolvedValue({
      id: 'job-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.Hybrid,
      category: 'IT',
      hasAllowance: true,
      requirements: 'ใช้ Flutter ได้',
      status: JobStatus.Open,
      companyName: 'InternFinder',
      businessType: 'ซอฟต์แวร์',
      companyDescription: 'แพลตฟอร์มฝึกงาน',
    });
    repository.findStudentId.mockResolvedValue('student-1');
    repository.isSaved.mockResolvedValue(true);

    const result = await service.getOpen(student, 'job-1');

    expect(repository.findOpenById).toHaveBeenCalledWith('job-1');
    expect(result.companyName).toBe('InternFinder');
    expect(result.businessType).toBe('ซอฟต์แวร์');
    expect(result.description).toBe('ช่วยพัฒนาแอป');
    expect(result.status).toBe(JobStatus.Open);
    expect(result.saved).toBe(true);
  });

  it('hides a missing or closed job from a student', async () => {
    repository.findOpenById.mockResolvedValue(null);

    await expect(service.getOpen(student, 'job-1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('rejects a company reading a job detail', async () => {
    await expect(service.getOpen(company, 'job-1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.findOpenById).not.toHaveBeenCalled();
  });

  it('saves an open job once for the signed-in student', async () => {
    repository.findStudentId.mockResolvedValue('student-1');
    repository.findOpenById.mockResolvedValue({ id: 'job-1' });

    await service.save(student, 'job-1');

    expect(repository.save).toHaveBeenCalledWith('student-1', 'job-1');
  });

  it('does not save a closed or missing job', async () => {
    repository.findStudentId.mockResolvedValue('student-1');
    repository.findOpenById.mockResolvedValue(null);

    await expect(service.save(student, 'job-1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(repository.save).not.toHaveBeenCalled();
  });

  it('rejects a company saving a job', async () => {
    await expect(service.save(company, 'job-1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.findStudentId).not.toHaveBeenCalled();
  });

  it('removes a saved job for the student', async () => {
    repository.findStudentId.mockResolvedValue('student-1');

    await service.unsave(student, 'job-1');

    expect(repository.unsave).toHaveBeenCalledWith('student-1', 'job-1');
  });

  it('lists only the open jobs this student saved', async () => {
    repository.findStudentId.mockResolvedValue('student-1');
    repository.listSaved.mockResolvedValue([
      {
        id: 'job-1',
        title: 'Flutter Intern',
        companyName: 'InternFinder',
        province: 'สงขลา',
        workMode: WorkMode.Hybrid,
        category: 'IT',
        hasAllowance: true,
        status: JobStatus.Open,
      },
    ]);

    const result = await service.listSaved(student);

    expect(repository.listSaved).toHaveBeenCalledWith('student-1');
    expect(result).toHaveLength(1);
    expect(result[0]?.title).toBe('Flutter Intern');
  });

  it('lists the company postings with an applicant count', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.listByCompany.mockResolvedValue([
      {
        id: 'job-1',
        title: 'Flutter Intern',
        status: JobStatus.Open,
        applicantCount: 0,
      },
      {
        id: 'job-2',
        title: 'งานที่ปิดแล้ว',
        status: JobStatus.Closed,
        applicantCount: 0,
      },
    ]);

    const result = await service.listMine(company);

    expect(repository.listByCompany).toHaveBeenCalledWith('company-1');
    expect(result.map((job) => job.status)).toEqual([
      JobStatus.Open,
      JobStatus.Closed,
    ]);
    expect(result[0]?.applicantCount).toBe(0);
  });

  it('rejects a student reading the company job list', async () => {
    await expect(service.listMine(student)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.listByCompany).not.toHaveBeenCalled();
  });
});
