import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { ForgotPasswordDto } from './dto/forgot-password.dto.js';
import { isPasswordRecoveryEmailValid } from './password-recovery-email.js';

describe('Password recovery email format policy', () => {
  it.each([
    'student@email.psu.ac.th',
    'faculty@psu.ac.th',
    ' Student@EMAIL.PSU.AC.TH ',
    ' FACULTY@PSU.AC.TH ',
    'student@gmail.com',
    'company@outlook.com',
    'student+intern@example.com',
    'student@department.psu.ac.th',
  ])('allows any normalized valid address %s', (email) => {
    expect(isPasswordRecoveryEmailValid(email)).toBe(true);
  });

  it.each([
    'student@psu.ac.th.',
    'student name@example.com',
    'student@example',
    `${'a'.repeat(65)}@example.com`,
    'student@@psu.ac.th',
    '@psu.ac.th',
    '',
    'psu.ac.th',
  ])('rejects a malformed address %s', (email) => {
    expect(isPasswordRecoveryEmailValid(email)).toBe(false);
  });
});

describe('ForgotPasswordDto input validation', () => {
  it('normalizes trim and case before validating a PSU email', async () => {
    const dto = plainToInstance(ForgotPasswordDto, {
      email: ' Student@EMAIL.PSU.AC.TH ',
    });

    expect(await validate(dto)).toEqual([]);
    expect(dto.email).toBe('student@email.psu.ac.th');
  });

  it('accepts the base PSU domain as well as its email domain', async () => {
    const dto = plainToInstance(ForgotPasswordDto, {
      email: 'faculty@psu.ac.th',
    });

    expect(await validate(dto)).toEqual([]);
  });

  it.each([
    'student@gmail.com',
    'company@outlook.com',
    'student+intern@example.com',
    'student@department.psu.ac.th',
    'student@psu.ac.th.attacker.example',
  ])(
    'accepts syntactically valid email %s at the API boundary regardless of domain',
    async (email) => {
      const dto = plainToInstance(ForgotPasswordDto, { email });

      expect(await validate(dto)).toEqual([]);
    },
  );

  it.each([
    'student@@psu.ac.th',
    '@psu.ac.th',
    'student@',
    'student name@psu.ac.th',
    42,
    null,
  ])('rejects an invalid email input %s', async (email) => {
    const dto = plainToInstance(ForgotPasswordDto, { email });

    expect(await validate(dto)).not.toEqual([]);
  });
});
