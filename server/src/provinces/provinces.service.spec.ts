import { BadRequestException } from '@nestjs/common';
import { PROVINCE_SEEDS } from '../database/migrations/province-seed-1791158400000.js';
import { ProvincesRepository } from './provinces.repository.js';
import { ProvincesService } from './provinces.service.js';

describe('province master', () => {
  it('contains all 77 Thai provinces with unique official codes and names', () => {
    expect(PROVINCE_SEEDS).toHaveLength(77);
    expect(new Set(PROVINCE_SEEDS.map((province) => province.id)).size).toBe(
      77,
    );
    expect(
      new Set(PROVINCE_SEEDS.map((province) => province.nameTh)).size,
    ).toBe(77);
    expect(PROVINCE_SEEDS.find((province) => province.id === 10)).toMatchObject(
      {
        nameTh: 'กรุงเทพมหานคร',
        aliases: expect.arrayContaining(['กทม.', 'กรุงเทพฯ']),
      },
    );
  });
});

describe('ProvincesService', () => {
  const repository = {
    list: vi.fn(),
    findById: vi.fn(),
    findByNameOrAlias: vi.fn(),
  };
  const service = new ProvincesService(
    repository as unknown as ProvincesRepository,
  );

  beforeEach(() => vi.clearAllMocks());

  it('returns official names and aliases', async () => {
    repository.list.mockResolvedValue([
      {
        id: 10,
        nameTh: 'กรุงเทพมหานคร',
        aliases: ['กทม.'],
      },
    ]);

    await expect(service.list()).resolves.toEqual([
      {
        id: 10,
        nameTh: 'กรุงเทพมหานคร',
        aliases: ['กทม.'],
      },
    ]);
  });

  it('resolves an alias to the canonical name', async () => {
    repository.findByNameOrAlias.mockResolvedValue({
      id: 10,
      nameTh: 'กรุงเทพมหานคร',
    });

    await expect(service.resolveName(' กทม. ')).resolves.toBe('กรุงเทพมหานคร');
    expect(repository.findByNameOrAlias).toHaveBeenCalledWith('กทม.');
  });

  it('rejects an unknown province name or id', async () => {
    repository.findByNameOrAlias.mockResolvedValue(null);
    repository.findById.mockResolvedValue(null);

    await expect(service.resolveName('ไม่มีจังหวัดนี้')).rejects.toBeInstanceOf(
      BadRequestException,
    );
    await expect(service.requireById(999)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});
