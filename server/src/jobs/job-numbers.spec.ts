import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { UserRole } from '../auth/user-role.js';
import { ProvincesService } from '../provinces/provinces.service.js';
import { StorageService } from '../storage/storage.service.js';
import { CreateJobDto } from './dto/create-job.dto.js';
import { UpdateJobDto } from './dto/update-job.dto.js';
import { JobFeedQueryDto } from './dto/job-feed-query.dto.js';
import { JobStatus, WorkMode } from './job-enums.js';
import { JobsRepository } from './jobs.repository.js';
import { JobsService } from './jobs.service.js';

const company = { userId: 'company-user', role: UserRole.Company };
const student = { userId: 'student-user', role: UserRole.Student };
const base = {
  title: 'Intern',
  description: 'Description',
  province: 'สงขลา',
  workMode: WorkMode.Remote,
  category: 'IT',
  hasAllowance: true,
  requirements: 'None',
};

describe('job openings and allowance service rules', () => {
  const repository = {
    findCompanyId: vi.fn(),
    create: vi.fn(),
    findById: vi.fn(),
    updateOwned: vi.fn(),
    findOpen: vi.fn(),
    findOpenById: vi.fn(),
    findStudentId: vi.fn(),
    listSaved: vi.fn(),
    isSaved: vi.fn(),
  };
  const service = new JobsService(
    repository as unknown as JobsRepository,
    {
      resolveName: async (name: string) => name,
    } as unknown as ProvincesService,
    {} as StorageService,
  );
  beforeEach(() => {
    vi.resetAllMocks();
    repository.findCompanyId.mockResolvedValue('company-id');
    repository.findStudentId.mockResolvedValue('student-id');
    repository.findById.mockResolvedValue({
      id: 'job',
      companyId: 'company-id',
    });
    repository.create.mockImplementation(async (input) => ({
      ...input,
      id: 'job',
      status: JobStatus.Open,
      version: 1,
    }));
    repository.updateOwned.mockImplementation(async (input) => ({
      ...input,
      status: JobStatus.Open,
      version: 2,
    }));
  });

  it.each([
    { openings: 3, allowanceAmount: 8000, hasAllowance: true },
    { openings: 1, allowanceAmount: 0, hasAllowance: true },
    { openings: null, allowanceAmount: 8000.25, hasAllowance: true },
    { openings: null, allowanceAmount: null, hasAllowance: true },
    { openings: 3, allowanceAmount: 8000, hasAllowance: false },
    { hasAllowance: false },
  ])('creates and updates optional amounts safely: %j', async (numbers) => {
    const dto = Object.assign(new CreateJobDto(), base, numbers);
    const expected = {
      openings: dto.openings ?? null,
      allowanceAmount: dto.hasAllowance ? (dto.allowanceAmount ?? null) : null,
    };
    const created = await service.create(company, dto);
    expect(created).toMatchObject(expected);
    expect(repository.create).toHaveBeenCalledWith(
      expect.objectContaining(expected),
    );
    const update = Object.assign(new UpdateJobDto(), dto, { version: 1 });
    expect(await service.update(company, 'job', update)).toMatchObject(
      expected,
    );
    expect(repository.updateOwned).toHaveBeenCalledWith(
      expect.objectContaining(expected),
    );
  });

  it.each([
    { openings: 0 },
    { openings: -1 },
    { openings: 1.5 },
    { openings: 2147483648 },
    { allowanceAmount: -1 },
    { allowanceAmount: 1.234 },
    { allowanceAmount: 1.0000000001 },
    { allowanceAmount: Infinity },
    { allowanceAmount: NaN },
    { allowanceAmount: 100000000 },
  ])(
    'rejects invalid values before create/update persistence: %j',
    async (numbers) => {
      const dto = Object.assign(new CreateJobDto(), base, numbers);
      await expect(service.create(company, dto)).rejects.toBeInstanceOf(
        BadRequestException,
      );
      await expect(
        service.update(
          company,
          'job',
          Object.assign(new UpdateJobDto(), dto, { version: 1 }),
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(repository.create).not.toHaveBeenCalled();
      expect(repository.updateOwned).not.toHaveBeenCalled();
    },
  );

  it('uses the same real numbers for feed, saved and job detail', async () => {
    const job = {
      ...base,
      id: 'job',
      companyName: 'Company',
      status: JobStatus.Open,
      openings: 3,
      allowanceAmount: 8000.25,
    };
    repository.findOpen.mockResolvedValue({ items: [job], total: 1 });
    repository.listSaved.mockResolvedValue({ items: [job], total: 1 });
    repository.findOpenById.mockResolvedValue(job);
    const feed = await service.listOpen(student, new JobFeedQueryDto());
    const saved = await service.listSaved(student, { page: 1, limit: 20 });
    const detail = await service.getOpen(student, 'job');
    for (const item of [feed.items[0], saved.items[0], detail]) {
      expect(item).toMatchObject({ openings: 3, allowanceAmount: 8000.25 });
    }
  });

  it.each([
    { openings: '3' },
    { openings: 0 },
    { allowanceAmount: '8000' },
    { allowanceAmount: 1.234 },
    { allowanceAmount: -1 },
  ])('DTO rejects invalid JSON types/ranges: %j', async (numbers) => {
    expect(
      (await validate(plainToInstance(CreateJobDto, { ...base, ...numbers })))
        .length,
    ).toBeGreaterThan(0);
  });
  it('DTO accepts absent and explicit null optional fields for legacy jobs', async () => {
    for (const numbers of [
      {},
      { openings: null, allowanceAmount: null },
      { openings: 3, allowanceAmount: 8000 },
    ]) {
      expect(
        await validate(plainToInstance(CreateJobDto, { ...base, ...numbers })),
      ).toEqual([]);
    }
  });
});
