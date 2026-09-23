import { Test } from '@nestjs/testing';
import { STORAGE_DRIVER, type StorageDriver } from './storage-driver.interface.js';
import { StorageService } from './storage.service.js';

describe('StorageService', () => {
  let service: StorageService;
  const driver: StorageDriver = {
    putObject: vi.fn(),
    getObject: vi.fn(),
    deleteObject: vi.fn(),
  };

  beforeEach(async () => {
    vi.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        StorageService,
        { provide: STORAGE_DRIVER, useValue: driver },
      ],
    }).compile();

    service = module.get(StorageService);
  });

  it('delegates put to driver and returns the key', async () => {
    const buffer = Buffer.from('test');
    const result = await service.put('resumes/123.pdf', buffer, 'application/pdf');

    expect(driver.putObject).toHaveBeenCalledWith(
      'resumes/123.pdf',
      buffer,
      'application/pdf',
    );
    expect(result).toBe('resumes/123.pdf');
  });

  it('delegates get to driver', async () => {
    const buffer = Buffer.from('pdf-data');
    vi.mocked(driver.getObject).mockResolvedValue(buffer);

    const result = await service.get('resumes/123.pdf');

    expect(driver.getObject).toHaveBeenCalledWith('resumes/123.pdf');
    expect(result).toBe(buffer);
  });

  it('delegates delete to driver', async () => {
    await service.delete('resumes/123.pdf');

    expect(driver.deleteObject).toHaveBeenCalledWith('resumes/123.pdf');
  });
});
