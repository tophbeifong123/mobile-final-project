import { BadRequestException } from '@nestjs/common';
import { UniversitiesRepository } from './universities.repository.js';
import { UniversitiesService } from './universities.service.js';

describe('UniversitiesService', () => {
  const repository = { search: vi.fn(), findById: vi.fn() };
  const service = new UniversitiesService(repository as unknown as UniversitiesRepository);

  beforeEach(() => vi.clearAllMocks());

  it('maps the master list to display DTOs without exposing aliases', async () => {
    repository.search.mockResolvedValue([
      { id: 'uni-1', nameTh: 'มหาวิทยาลัยสงขลานครินทร์', aliases: ['ม.อ.', 'PSU'] },
    ]);
    await expect(service.search('PSU')).resolves.toEqual([
      { id: 'uni-1', nameTh: 'มหาวิทยาลัยสงขลานครินทร์' },
    ]);
    expect(repository.search).toHaveBeenCalledWith('PSU');
  });

  it('rejects search terms over 100 characters before querying', async () => {
    await expect(service.search('a'.repeat(101))).rejects.toBeInstanceOf(BadRequestException);
    expect(repository.search).not.toHaveBeenCalled();
  });

  it('rejects an unknown university id', async () => {
    repository.findById.mockResolvedValue(null);
    await expect(service.requireById('missing')).rejects.toBeInstanceOf(BadRequestException);
  });
});
