import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '../auth/user-role.js';
import { ProvincesService } from '../provinces/provinces.service.js';
import { StorageService } from '../storage/storage.service.js';
import { CreateJobDto } from './dto/create-job.dto.js';
import { JobFeedQueryDto } from './dto/job-feed-query.dto.js';
import { UpdateJobDto } from './dto/update-job.dto.js';
import { UpdateJobStatusDto } from './dto/update-job-status.dto.js';
import { JobStatus, WorkMode } from './job-enums.js';
import { JobsRepository, JobVersionConflictError } from './jobs.repository.js';
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
    findById: vi.fn(),
    updateOwned: vi.fn(),
    updateOwnedStatus: vi.fn(),
    deleteOwned: vi.fn(),
    listByCompany: vi.fn(),
    countApplicants: vi.fn(),
  };
  const provincesService = { resolveName: vi.fn() };

  let service: JobsService;
  const storage = { get: vi.fn() };

  const company = { userId: 'user-1', role: UserRole.Company };
  const student = { userId: 'user-2', role: UserRole.Student };

  beforeEach(async () => {
    vi.clearAllMocks();
    provincesService.resolveName.mockImplementation(async (name: string) =>
      name.trim(),
    );
    const module = await Test.createTestingModule({
      providers: [
        JobsService,
        { provide: JobsRepository, useValue: repository },
        { provide: ProvincesService, useValue: provincesService },
        { provide: StorageService, useValue: storage },
      ],
    }).compile();
    service = module.get(JobsService);
  });

  it('preserves total/page metadata and maps the same card fields in feed and saved jobs', async () => {
    const createdAt = new Date('2026-10-01T12:00:00Z');
    const item = { id: 'job-21', title: 'Intern', companyName: 'Company', province: 'สงขลา',
      workMode: WorkMode.Remote, category: 'IT', hasAllowance: false, status: JobStatus.Open,
      createdAt, companyLogoObjectKey: 'company-logos/company/logo.png' };
    repository.findOpen.mockResolvedValue({ items: [item], total: 21 });
    repository.findStudentId.mockResolvedValue('student-1');
    repository.listSaved.mockResolvedValue({ items: [item], total: 21 });
    const query = Object.assign(new JobFeedQueryDto(), { page: 2, limit: 20 });
    const feed = await service.listOpen(student, query);
    const saved = await service.listSaved(student, { page: 2, limit: 20 });
    expect(feed).toEqual(expect.objectContaining({ total: 21, totalPages: 2, page: 2, limit: 20 }));
    expect(saved).toEqual(feed);
    expect(feed.items[0]).toEqual(expect.objectContaining({ createdAt, companyLogoAvailable: true, hasAllowance: false }));
    expect(feed.items[0]).not.toHaveProperty('companyLogoObjectKey');
    expect(repository.findOpen).toHaveBeenCalledWith(expect.objectContaining({ page: 2, limit: 20 }));
  });

  it('returns zero pages for empty feed', async () => {
    repository.findOpen.mockResolvedValue({ items: [], total: 0 });
    expect(await service.listOpen(student, new JobFeedQueryDto())).toEqual({ items: [], total: 0, totalPages: 0, page: 1, limit: 20 });
  });

  it('creates an open job for the signed-in company', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.create.mockResolvedValue({
      id: 'job-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.Hybrid,
      category: 'IT & Software',
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
    dto.category = ' IT & Software ';
    dto.hasAllowance = true;
    dto.allowanceAmount = 8000;
    dto.requirements = ' ใช้ Flutter ได้ ';

    const result = await service.create(company, dto);

    expect(repository.create).toHaveBeenCalledWith({
      openings: null, allowanceAmount: null,
      companyId: 'company-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.Hybrid,
      category: 'IT & Software',
      hasAllowance: true,
      allowanceAmount: 8000,
      requirements: 'ใช้ Flutter ได้',
      skills: [],
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
    dto.category = 'IT & Software';
    dto.hasAllowance = false;
    dto.requirements = 'คุณสมบัติ';

    await expect(service.create(student, dto)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.findCompanyId).not.toHaveBeenCalled();
  });

  it('stores a canonical province for a colloquial job province', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    provincesService.resolveName.mockResolvedValue('กรุงเทพมหานคร');
    repository.create.mockResolvedValue({
      id: 'job-1',
      title: 'งาน',
      province: 'กรุงเทพมหานคร',
      status: JobStatus.Open,
    });
    const dto = new CreateJobDto();
    dto.title = 'งาน';
    dto.description = 'รายละเอียด';
    dto.province = 'กทม.';
    dto.workMode = WorkMode.OnSite;
    dto.category = 'IT & Software';
    dto.hasAllowance = false;
    dto.requirements = 'คุณสมบัติ';

    await service.create(company, dto);

    expect(provincesService.resolveName).toHaveBeenCalledWith('กทม.');
    expect(repository.create).toHaveBeenCalledWith(
      expect.objectContaining({ province: 'กรุงเทพมหานคร' }),
    );
  });

  it('rejects a job province absent from the master', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    provincesService.resolveName.mockRejectedValue(
      new BadRequestException('ไม่พบจังหวัดที่เลือก'),
    );
    const dto = new CreateJobDto();
    dto.province = 'ไม่มีจังหวัดนี้';

    await expect(service.create(company, dto)).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('returns not found when the company profile row is missing', async () => {
    repository.findCompanyId.mockResolvedValue(null);
    const dto = new CreateJobDto();
    dto.title = 'งาน';
    dto.description = 'รายละเอียด';
    dto.province = 'สงขลา';
    dto.workMode = WorkMode.OnSite;
    dto.category = 'IT & Software';
    dto.hasAllowance = false;
    dto.requirements = 'คุณสมบัติ';

    await expect(service.create(company, dto)).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('returns only the open jobs the repository finds for a student', async () => {
    repository.findOpen.mockResolvedValue({
      items: [
        {
          id: 'job-1',
          title: 'Flutter Intern',
          companyName: 'InternFinder',
          province: 'สงขลา',
          workMode: WorkMode.Hybrid,
          category: 'IT & Software',
          hasAllowance: true,
          status: JobStatus.Open,
        },
      ],
      total: 1,
    });
    const query = new JobFeedQueryDto();
    query.search = 'flutter';
    query.province = 'สงขลา';
    query.workMode = WorkMode.Hybrid;
    query.category = 'IT & Software';
    query.hasAllowance = true;

    const result = await service.listOpen(student, query);

    expect(repository.findOpen).toHaveBeenCalledWith({
      search: 'flutter',
      province: 'สงขลา',
      workMode: WorkMode.Hybrid,
      category: 'IT & Software',
      hasAllowance: true,
      page: 1,
      limit: 20,
    });
    expect(result.items).toHaveLength(1);
    expect(result.total).toBe(1);
    expect(result.page).toBe(1);
    expect(result.limit).toBe(20);
    expect(result.totalPages).toBe(1);
    expect(result.items[0]?.status).toBe(JobStatus.Open);
    expect(result.items[0]?.companyName).toBe('InternFinder');
  });

  it('filters open jobs by skills', async () => {
    repository.findOpen.mockResolvedValue({
      items: [
        {
          id: 'job-1',
          title: 'Flutter Developer',
          companyName: 'InternFinder',
          province: 'สงขลา',
          workMode: WorkMode.Hybrid,
          category: 'IT & Software',
          hasAllowance: true,
          skills: ['Flutter', 'Dart'],
          status: JobStatus.Open,
        },
      ],
      total: 1,
    });
    const query = new JobFeedQueryDto();
    query.skills = ['Flutter', 'Dart'];

    const result = await service.listOpen(student, query);

    expect(repository.findOpen).toHaveBeenCalledWith({
      search: undefined,
      province: undefined,
      workMode: undefined,
      category: undefined,
      hasAllowance: undefined,
      skills: ['Flutter', 'Dart'],
      page: 1,
      limit: 20,
    });
    expect(result.items).toHaveLength(1);
    expect(result.items[0]?.skills).toEqual(['Flutter', 'Dart']);
  });

  it('uses the canonical province name to filter the student feed', async () => {
    provincesService.resolveName.mockResolvedValue('กรุงเทพมหานคร');
    repository.findOpen.mockResolvedValue({ items: [], total: 0 });
    const query = new JobFeedQueryDto();
    query.province = 'กรุงเทพฯ';

    await service.listOpen(student, query);

    expect(repository.findOpen).toHaveBeenCalledWith(
      expect.objectContaining({ province: 'กรุงเทพมหานคร' }),
    );
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
      category: 'IT & Software',
      hasAllowance: true,
      requirements: 'ใช้ Flutter ได้',
      status: JobStatus.Open,
      companyName: 'InternFinder',
      businessType: 'ซอฟต์แวร์',
      companyDescription: 'แพลตฟอร์มฝึกงาน',
      companyWebsiteUrl: 'https://example.com',
      companySize: '51-200',
      companyPerks: ['MacBook', 'Free Lunch'],
      companyLocation: 'อาคาร A ถนนนิพัทธ์อุทิศ',
      companyLogoObjectKey: 'company-logos/company-1/logo.png',
    });
    repository.findStudentId.mockResolvedValue('student-1');
    repository.isSaved.mockResolvedValue(true);

    const result = await service.getOpen(student, 'job-1');

    expect(repository.findOpenById).toHaveBeenCalledWith('job-1');
    expect(result.companyName).toBe('InternFinder');
    expect(result.businessType).toBe('ซอฟต์แวร์');
    expect(result.companyDescription).toBe('แพลตฟอร์มฝึกงาน');
    expect(result.companyWebsiteUrl).toBe('https://example.com');
    expect(result.companySize).toBe('51-200');
    expect(result.companyPerks).toEqual(['MacBook', 'Free Lunch']);
    expect(result.companyLocation).toBe('อาคาร A ถนนนิพัทธ์อุทิศ');
    expect(result.companyLogoAvailable).toBe(true);
    expect(result).not.toHaveProperty('companyLogoObjectKey');
    expect(result.description).toBe('ช่วยพัฒนาแอป');
    expect(result.status).toBe(JobStatus.Open);
    expect(result.saved).toBe(true);
  });

  it.each([
    ['png', 'image/png'],
    ['jpg', 'image/jpeg'],
    ['jpeg', 'image/jpeg'],
    ['webp', 'image/webp'],
    ['gif', 'image/gif'],
    ['svg', 'image/svg+xml'],
  ])(
    'serves the saved %s logo only for an open job',
    async (extension, mimeType) => {
      const key = 'company-logos/company-1/logo.' + extension;
      repository.findOpenById.mockResolvedValue({ companyLogoObjectKey: key });
      storage.get.mockResolvedValue(Buffer.from('logo'));
      const result = await service.getCompanyLogo(student, 'job-1');
      expect(storage.get).toHaveBeenCalledWith(key);
      expect(result).toEqual({ buffer: Buffer.from('logo'), mimeType });
    },
  );

  it('rejects company access to the student logo endpoint before storage access', async () => {
    await expect(
      service.getCompanyLogo(company, 'job-1'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(repository.findOpenById).not.toHaveBeenCalled();
    expect(storage.get).not.toHaveBeenCalled();
  });

  it.each([null, { companyLogoObjectKey: null }])(
    'hides missing/closed jobs or absent logos',
    async (job) => {
      repository.findOpenById.mockResolvedValue(job);
      await expect(
        service.getCompanyLogo(student, 'job-1'),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(storage.get).not.toHaveBeenCalled();
    },
  );

  it('returns not found when a stored logo is gone', async () => {
    repository.findOpenById.mockResolvedValue({
      companyLogoObjectKey: 'company-logos/company-1/logo.png',
    });
    storage.get.mockResolvedValue(null);
    await expect(
      service.getCompanyLogo(student, 'job-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns empty company metadata for legacy profiles without inventing values', async () => {
    repository.findOpenById.mockResolvedValue({
      id: 'job-1',
      companyName: 'Company',
    });
    repository.findStudentId.mockResolvedValue(null);
    const result = await service.getOpen(student, 'job-1');
    expect(result.companyWebsiteUrl).toBe('');
    expect(result.companySize).toBe('');
    expect(result.companyLocation).toBe('');
    expect(result.companyPerks).toEqual([]);
    expect(result.companyLogoAvailable).toBe(false);
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
    repository.listSaved.mockResolvedValue({
      items: [
        {
          id: 'job-1',
          title: 'Flutter Intern',
          companyName: 'InternFinder',
          province: 'สงขลา',
          workMode: WorkMode.Hybrid,
          category: 'IT & Software',
          hasAllowance: true,
          status: JobStatus.Open,
        },
      ],
      total: 1,
    });

    const result = await service.listSaved(student);

    expect(repository.listSaved).toHaveBeenCalledWith('student-1', {
      page: 1,
      limit: 20,
    });
    expect(result.items).toHaveLength(1);
    expect(result.total).toBe(1);
    expect(result.items[0]?.title).toBe('Flutter Intern');
  });

  it('lists the company postings with an applicant count', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.listByCompany.mockResolvedValue({
      items: [
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
      ],
      total: 2,
    });

    const result = await service.listMine(company);

    expect(repository.listByCompany).toHaveBeenCalledWith('company-1', {
      page: 1,
      limit: 20,
    });
    expect(result.items.map((job) => job.status)).toEqual([
      JobStatus.Open,
      JobStatus.Closed,
    ]);
    expect(result.total).toBe(2);
    expect(result.items[0]?.applicantCount).toBe(0);
  });

  it('returns an owned posting with applicant counts and deadline', async () => {
    const deadline = new Date('2026-12-31T00:00:00.000Z');
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.findById.mockResolvedValue({
      id: 'job-1',
      companyId: 'company-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.Hybrid,
      category: 'IT & Software',
      hasAllowance: true,
      requirements: 'ใช้ Flutter ได้',
      skills: ['Flutter'],
      status: JobStatus.Closed,
      version: 3,
      deadline,
    });
    repository.countApplicants.mockResolvedValue({
      applicantCount: 4,
      pendingApplicantCount: 2,
    });

    const result = await service.getMine(company, 'job-1');

    expect(repository.countApplicants).toHaveBeenCalledWith('job-1');
    expect(result.applicantCount).toBe(4);
    expect(result.pendingApplicantCount).toBe(2);
    expect(result.deadline).toEqual(deadline);
    expect(result.status).toBe(JobStatus.Closed);
    expect(result.skills).toEqual(['Flutter']);
  });

  it('does not count applicants for a posting the company does not own', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.findById.mockResolvedValue({
      id: 'job-1',
      companyId: 'company-2',
    });

    await expect(service.getMine(company, 'job-1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.countApplicants).not.toHaveBeenCalled();
  });

  it('rejects a student reading one company posting', async () => {
    await expect(service.getMine(student, 'job-1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.countApplicants).not.toHaveBeenCalled();
  });

  it('rejects a student reading the company job list', async () => {
    await expect(service.listMine(student)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.listByCompany).not.toHaveBeenCalled();
  });

  it('updates the company posting when the version matches', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.findById.mockResolvedValue({
      id: 'job-1',
      companyId: 'company-1',
    });
    repository.updateOwned.mockResolvedValue({
      id: 'job-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.Remote,
      category: 'IT & Software',
      hasAllowance: false,
      requirements: 'ใช้ Flutter ได้',
      status: JobStatus.Open,
      version: 2,
    });
    const dto = new UpdateJobDto();
    dto.title = ' Flutter Intern ';
    dto.description = ' ช่วยพัฒนาแอป ';
    dto.province = ' สงขลา ';
    dto.workMode = WorkMode.Remote;
    dto.category = ' IT & Software ';
    dto.hasAllowance = false;
    dto.requirements = ' ใช้ Flutter ได้ ';
    dto.version = 1;

    const result = await service.update(company, 'job-1', dto);

    expect(repository.updateOwned).toHaveBeenCalledWith({
      openings: null, allowanceAmount: null,
      id: 'job-1',
      companyId: 'company-1',
      version: 1,
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.Remote,
      category: 'IT & Software',
      hasAllowance: false,
      allowanceAmount: null,
      requirements: 'ใช้ Flutter ได้',
      skills: [],
    });
    expect(result.version).toBe(2);
  });

  it('rejects an update when the posting version is stale', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.findById.mockResolvedValue({
      id: 'job-1',
      companyId: 'company-1',
    });
    repository.updateOwned.mockRejectedValue(new JobVersionConflictError());
    const dto = new UpdateJobDto();
    dto.title = 'งาน';
    dto.description = 'รายละเอียด';
    dto.province = 'สงขลา';
    dto.workMode = WorkMode.Hybrid;
    dto.category = 'IT & Software';
    dto.hasAllowance = false;
    dto.requirements = 'คุณสมบัติ';
    dto.version = 1;

    await expect(service.update(company, 'job-1', dto)).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('rejects a company editing another company posting', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.findById.mockResolvedValue({
      id: 'job-1',
      companyId: 'company-2',
    });
    const dto = new UpdateJobDto();
    dto.title = 'งาน';
    dto.description = 'รายละเอียด';
    dto.province = 'สงขลา';
    dto.workMode = WorkMode.Hybrid;
    dto.category = 'IT & Software';
    dto.hasAllowance = false;
    dto.requirements = 'คุณสมบัติ';
    dto.version = 1;

    await expect(service.update(company, 'job-1', dto)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.updateOwned).not.toHaveBeenCalled();
  });

  it('deletes the company posting', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.findById.mockResolvedValue({
      id: 'job-1',
      companyId: 'company-1',
    });
    repository.deleteOwned.mockResolvedValue(true);

    await service.remove(company, 'job-1');

    expect(repository.deleteOwned).toHaveBeenCalledWith('job-1', 'company-1');
  });

  it('does not delete a missing posting', async () => {
    repository.findCompanyId.mockResolvedValue('company-1');
    repository.findById.mockResolvedValue(null);

    await expect(service.remove(company, 'job-1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(repository.deleteOwned).not.toHaveBeenCalled();
  });

  describe('updateStatus', () => {
    it('updates status from open to closed', async () => {
      repository.findCompanyId.mockResolvedValue('company-1');
      repository.findById.mockResolvedValue({
        id: 'job-1',
        companyId: 'company-1',
      });
      repository.updateOwnedStatus.mockResolvedValue({
        id: 'job-1',
        title: 'Flutter Intern',
        description: 'คำอธิบาย',
        province: 'สงขลา',
        workMode: WorkMode.Hybrid,
        category: 'IT & Software',
        hasAllowance: true,
        requirements: 'คุณสมบัติ',
        status: JobStatus.Closed,
        version: 2,
      });

      const dto = new UpdateJobStatusDto();
      dto.status = JobStatus.Closed;

      const result = await service.updateStatus(company, 'job-1', dto);

      expect(repository.updateOwnedStatus).toHaveBeenCalledWith(
        'job-1',
        'company-1',
        JobStatus.Closed,
      );
      expect(result.status).toBe(JobStatus.Closed);
      expect(result.version).toBe(2);
    });

    it('updates status from closed to open', async () => {
      repository.findCompanyId.mockResolvedValue('company-1');
      repository.findById.mockResolvedValue({
        id: 'job-1',
        companyId: 'company-1',
      });
      repository.updateOwnedStatus.mockResolvedValue({
        id: 'job-1',
        title: 'Flutter Intern',
        description: 'คำอธิบาย',
        province: 'สงขลา',
        workMode: WorkMode.Hybrid,
        category: 'IT & Software',
        hasAllowance: true,
        requirements: 'คุณสมบัติ',
        status: JobStatus.Open,
        version: 3,
      });

      const dto = new UpdateJobStatusDto();
      dto.status = JobStatus.Open;

      const result = await service.updateStatus(company, 'job-1', dto);

      expect(repository.updateOwnedStatus).toHaveBeenCalledWith(
        'job-1',
        'company-1',
        JobStatus.Open,
      );
      expect(result.status).toBe(JobStatus.Open);
    });

    it('rejects a student changing status', async () => {
      const dto = new UpdateJobStatusDto();
      dto.status = JobStatus.Closed;

      await expect(
        service.updateStatus(student, 'job-1', dto),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(repository.updateOwnedStatus).not.toHaveBeenCalled();
    });

    it('rejects changing status of another company job', async () => {
      repository.findCompanyId.mockResolvedValue('company-1');
      repository.findById.mockResolvedValue({
        id: 'job-1',
        companyId: 'company-2',
      });
      const dto = new UpdateJobStatusDto();
      dto.status = JobStatus.Closed;

      await expect(
        service.updateStatus(company, 'job-1', dto),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(repository.updateOwnedStatus).not.toHaveBeenCalled();
    });

    it('returns not found if job does not exist', async () => {
      repository.findCompanyId.mockResolvedValue('company-1');
      repository.findById.mockResolvedValue(null);
      const dto = new UpdateJobStatusDto();
      dto.status = JobStatus.Closed;

      await expect(
        service.updateStatus(company, 'job-1', dto),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(repository.updateOwnedStatus).not.toHaveBeenCalled();
    });
  });
});
