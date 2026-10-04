export const PASSWORD_RECOVERY_EMAIL_PATTERN = /^[^\s@]+@(?:email\.)?psu\.ac\.th$/i;

export const PASSWORD_RECOVERY_EMAIL_MESSAGE =
  'รองรับการรีเซ็ตรหัสผ่านเฉพาะอีเมล @email.psu.ac.th หรือ @psu.ac.th';

export function isPasswordRecoveryEmailAllowed(email: string): boolean {
  return PASSWORD_RECOVERY_EMAIL_PATTERN.test(email.trim());
}
