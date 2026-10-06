import { BadRequestException } from '@nestjs/common';
import { MajorsRepository } from './majors.repository.js';
import { MajorsService } from './majors.service.js';

describe('MajorsService', () => {
  const repository = { search: vi.fn(), findById: vi.fn() };
  const service = new MajorsService(repository as unknown as MajorsRepository);

  beforeEach(() => vi.clearAllMocks());

  it('returns suggestions from the repository', async () => {
    repository.search.mockResolvedValue([{ id: '1', nameTh: 'วิศวกรรมคอมพิวเตอร์' }]);
    await expect(service.search('วิศว')).resolves.toEqual([{ id: '1', nameTh: 'วิศวกรรมคอมพิวเตอร์' }]);
  });

  it('rejects overly long queries', async () => {
    await expect(service.search('ก'.repeat(101))).rejects.toBeInstanceOf(BadRequestException);
    expect(repository.search).not.toHaveBeenCalled();
  });

  it('rejects an unknown major ID', async () => {
    repository.findById.mockResolvedValue(null);
    await expect(service.requireById('missing')).rejects.toBeInstanceOf(BadRequestException);
  });
});
