import { createHash, randomBytes } from 'node:crypto';
import { BadRequestException, ConflictException, Inject, Injectable, Logger } from '@nestjs/common';
import { AuthRepository } from './auth.repository.js';
import { ForgotPasswordDto } from './dto/forgot-password.dto.js';
import { PasswordRecoveryResponseDto } from './dto/password-recovery-response.dto.js';
import { ResetPasswordDto } from './dto/reset-password.dto.js';
import { PASSWORD_HASHER, type PasswordHasher } from './password-hasher.js';
import { PasswordResetMailer } from './password-reset-mailer.js';
import { isPasswordRecoveryEmailValid, PASSWORD_RECOVERY_EMAIL_MESSAGE } from './password-recovery-email.js';
import { validateRegistrationPassword } from './registration-password-policy.js';

export const PASSWORD_RESET_REQUEST_MESSAGE = 'หากอีเมลนี้มีบัญชีอยู่ ระบบจะส่งลิงก์รีเซ็ตรหัสผ่านให้คุณ';
const INVALID_RESET = 'ลิงก์รีเซ็ตรหัสผ่านไม่ถูกต้องหรือหมดอายุ กรุณาขอลิงก์ใหม่';

@Injectable()
export class PasswordRecoveryService {
  private readonly logger = new Logger(PasswordRecoveryService.name);

  constructor(
    private readonly repository: AuthRepository,
    private readonly mailer: PasswordResetMailer,
    @Inject(PASSWORD_HASHER) private readonly passwords: PasswordHasher,
  ) {}

  async forgotPassword(dto: ForgotPasswordDto): Promise<PasswordRecoveryResponseDto> {
    const email = dto.email.trim().toLowerCase();
    if (!isPasswordRecoveryEmailValid(email)) {
      throw new BadRequestException(PASSWORD_RECOVERY_EMAIL_MESSAGE);
    }
    // Configuration failures apply equally to existing and unknown accounts.
    this.mailer.assertConfigured();
    const started = Date.now();
    const user = await this.repository.findByEmail(email);
    if (user) {
      const token = randomBytes(32).toString('hex');
      const tokenHash = hashResetToken(token);
      const issued = await this.repository.replacePasswordResetToken({
        userId: user.id,
        tokenHash,
        expiresAt: new Date(Date.now() + 15 * 60_000),
      });
      if (issued) {
        // SMTP is off the response path so delivery latency cannot enumerate users.
        void this.mailer.sendResetLink(user.email, token).catch(async () => {
          this.logger.error('Password reset email delivery failed; check SMTP configuration/connectivity');
          try {
            await this.repository.deletePasswordResetToken(tokenHash);
          } catch {
            this.logger.error('Could not invalidate the undelivered reset token');
          }
        });
      }
    }
    await new Promise<void>((resolve) => setTimeout(resolve, Math.max(0, 200 - (Date.now() - started))));
    return { message: PASSWORD_RESET_REQUEST_MESSAGE };
  }

  async resetPassword(dto: ResetPasswordDto): Promise<PasswordRecoveryResponseDto> {
    const tokenHash = hashResetToken(dto.token);
    const token = await this.repository.findPasswordResetToken(tokenHash);
    if (!token || token.expiresAt.getTime() <= Date.now()) {
      throw new BadRequestException(INVALID_RESET);
    }
    const user = await this.repository.findById(token.userId);
    if (!user) {
      throw new BadRequestException(INVALID_RESET);
    }
    // Reject weak passwords before hashing or consuming the one-use token.
    validateRegistrationPassword(dto.password);
    const passwordHash = await this.passwords.hash(dto.password);
    const result = await this.repository.consumePasswordResetToken(
      tokenHash,
      passwordHash,
      (currentHash) => this.passwords.verify(dto.password, currentHash),
    );
    if (!result) {
      throw new BadRequestException(INVALID_RESET);
    }
    if (result.status === 'reused') {
      throw new ConflictException({
        statusCode: 409,
        code: 'PASSWORD_REUSE',
        message: 'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม',
      });
    }
    void this.mailer.sendPasswordChanged(result.email).catch(() => {
      this.logger.error('Password change notification could not be delivered');
    });
    return { message: 'ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว กรุณาเข้าสู่ระบบอีกครั้ง' };
  }
}

function hashResetToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
