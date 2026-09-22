import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '../auth/user-role.js';
import { UpdateStudentProfileDto } from './dto/update-student-profile.dto.js';
import { StudentsRepository } from './students.repository.js';
import { StudentsService } from './students.service.js';

describe('StudentsService', () => {
  const repository = {
    findByUserId: vi.fn(),
    updateByUserId: vi.fn(),
  };

  let service: StudentsService;

  const student = { userId: 'user-1', role: UserRole.Student };
  const company = { userId: 'user-2', role: UserRole.Company };
  const stored = {
    fullName: 'มีนา',
    university: 'PSU',
    major: 'IT',
    skills: ['Flutter'],
    portfolioUrl: null,
  };

  beforeEach(async () => {
    vi.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        StudentsService,
        { provide: StudentsRepository, useValue: repository },
      ],
    }).compile();
    service = module.get(StudentsService);
  });

  it('returns the signed-in student profile', async () => {
    repository.findByUserId.mockResolvedValue(stored);

    const result = await service.getMine(student);

    expect(repository.findByUserId).toHaveBeenCalledWith('user-1');
    expect(result).toMatchObject(stored);
  });

  it('rejects a company reading a student profile', async () => {
    await expect(service.getMine(company)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.findByUserId).not.toHaveBeenCalled();
  });

  it('returns not found when the student has no profile row', async () => {
    repository.findByUserId.mockResolvedValue(null);

    await expect(service.getMine(student)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('saves trimmed profile fields and clears a blank portfolio', async () => {
    repository.updateByUserId.mockResolvedValue({
      fullName: 'มีนา',
      university: 'PSU',
      major: 'IT',
      skills: ['Flutter', 'SQL'],
      portfolioUrl: null,
    });
    const dto = new UpdateStudentProfileDto();
    dto.fullName = '  มีนา  ';
    dto.university = ' PSU ';
    dto.major = ' IT ';
    dto.skills = [' Flutter ', '', 'SQL'];
    dto.portfolioUrl = '   ';

    const result = await service.updateMine(student, dto);

    expect(repository.updateByUserId).toHaveBeenCalledWith('user-1', {
      fullName: 'มีนา',
      university: 'PSU',
      major: 'IT',
      skills: ['Flutter', 'SQL'],
      portfolioUrl: null,
    });
    expect(result.portfolioUrl).toBeNull();
    expect(result.skills).toEqual(['Flutter', 'SQL']);
  });

  it('rejects a company updating a student profile', async () => {
    const dto = new UpdateStudentProfileDto();
    dto.fullName = 'บริษัท';
    dto.university = 'PSU';
    dto.major = 'IT';
    dto.skills = [];

    await expect(service.updateMine(company, dto)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(repository.updateByUserId).not.toHaveBeenCalled();
  });
});
