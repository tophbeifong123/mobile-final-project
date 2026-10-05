import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { ForgotPasswordDto } from './dto/forgot-password.dto.js';
import { isPasswordRecoveryEmailAllowed } from './password-recovery-email.js';

describe('Password recovery PSU email policy', () => {
  it.each([
    'student@email.psu.ac.th',
    'faculty@psu.ac.th',
    ' Student@EMAIL.PSU.AC.TH ',
    ' FACULTY@PSU.AC.TH ',
  ])('allows the exact normalized PSU address %s', (email) => {
    expect(isPasswordRecoveryEmailAllowed(email)).toBe(true);
  });

  it.each([
    'student@gmail.com',
    'student@outlook.com',
    'student@example.com',
    'student@department.psu.ac.th',
    'student@department.email.psu.ac.th',
    'student@psu.ac.th.attacker.example',
    'student@fakepsu.ac.th',
    'student@psu.ac.th.',
    'student@emailpsu.ac.th',
    'student@@psu.ac.th',
    '@psu.ac.th',
    '',
    'psu.ac.th',
  ])('rejects an unapproved domain or malformed address %s', (email) => {
    expect(isPasswordRecoveryEmailAllowed(email)).toBe(false);
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
    'student@department.psu.ac.th',
    'student@psu.ac.th.attacker.example',
  ])(
    'rejects syntactically valid but unapproved email %s at the API boundary',
    async (email) => {
      const dto = plainToInstance(ForgotPasswordDto, { email });

      expect(await validate(dto)).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            property: 'email',
            constraints: expect.objectContaining({
              matches: expect.any(String),
            }),
          }),
        ]),
      );
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
