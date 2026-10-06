import { isEmail } from 'class-validator';

export const PASSWORD_RECOVERY_EMAIL_MESSAGE =
  'กรอกอีเมลให้ถูกต้อง';

export function isPasswordRecoveryEmailValid(email: string): boolean {
  const normalized = email.trim();
  return normalized.length <= 255 && isEmail(normalized);
}
