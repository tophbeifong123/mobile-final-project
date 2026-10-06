import { BadRequestException } from '@nestjs/common';
import { validateRegistrationPassword } from './registration-password-policy.js';

describe('Registration password policy', () => {
  it.each([
    'Abcdef1!',
    'Aa1!' + 'a'.repeat(68),
    'Aa1!' + 'ก'.repeat(22) + 'aa',
  ])('accepts valid password including byte boundaries', (password) => {
    expect(() => validateRegistrationPassword(password)).not.toThrow();
  });
  it.each([
    'abcdef1!',
    'ABCDEF1!',
    'Abcdefg!',
    'Abcdef12',
    'Abcdef1 ',
    'Abcdef1🔐',
    'Aa1!',
    'Aa1!' + 'a'.repeat(69),
    'Aa1!' + 'ก'.repeat(23),
  ])('rejects missing conditions or excessive bytes', (password) => {
    expect(() => validateRegistrationPassword(password)).toThrow(
      BadRequestException,
    );
  });
});
