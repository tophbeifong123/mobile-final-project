import { BadRequestException } from '@nestjs/common';

/** Signup only: existing accounts can still log in with their current password. */
export function validateRegistrationPassword(password: string): void {
  const conditions: [boolean, string][] = [
    [Array.from(password).length >= 8, 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'],
    [Buffer.byteLength(password, 'utf8') <= 72, 'รหัสผ่านต้องไม่เกิน 72 ไบต์'],
    [
      /[A-Z]/.test(password),
      'ต้องมีตัวอักษรภาษาอังกฤษพิมพ์ใหญ่อย่างน้อย 1 ตัว',
    ],
    [
      /[a-z]/.test(password),
      'ต้องมีตัวอักษรภาษาอังกฤษพิมพ์เล็กอย่างน้อย 1 ตัว',
    ],
    [/[0-9]/.test(password), 'ต้องมีตัวเลขอย่างน้อย 1 ตัว'],
    [
      /[\x21-\x2f\x3a-\x40\x5b-\x60\x7b-\x7e]/.test(password),
      'ต้องมีอักขระพิเศษอย่างน้อย 1 ตัว',
    ],
  ];
  const missing = conditions
    .filter(([passed]) => !passed)
    .map(([, message]) => message);
  if (missing.length) throw new BadRequestException(missing);
}
