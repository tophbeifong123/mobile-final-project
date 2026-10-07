import { validate } from 'class-validator';
import { UpdateStudentProfileDto } from './update-student-profile.dto.js';

describe('UpdateStudentProfileDto', () => {
  function dtoWithCustomMajor(name: string): UpdateStudentProfileDto {
    const dto = new UpdateStudentProfileDto();
    dto.fullName = 'มีนา';
    dto.skills = [];
    dto.customMajorName = name;
    return dto;
  }

  it('accepts a custom major name up to the database limit', async () => {
    await expect(validate(dtoWithCustomMajor('ก'.repeat(255)))).resolves.toHaveLength(0);
  });

  it('rejects a custom major name longer than the database limit', async () => {
    const errors = await validate(dtoWithCustomMajor('ก'.repeat(256)));
    expect(errors.some((error) => error.property === 'customMajorName')).toBe(true);
  });
});
