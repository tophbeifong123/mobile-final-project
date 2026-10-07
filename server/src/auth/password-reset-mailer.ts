import { Injectable, type OnModuleDestroy, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer, { type Transporter } from 'nodemailer';

@Injectable()
export class PasswordResetMailer implements OnModuleDestroy {
  private transport?: Transporter;

  constructor(private readonly config: ConfigService) {}

  assertConfigured(): void {
    const host = this.config.get<string>('SMTP_HOST');
    const from = this.config.get<string>('SMTP_FROM');
    const port = Number(this.config.get<string>('SMTP_PORT', '587'));
    const user = this.config.get<string>('SMTP_USER');
    const password = this.config.get<string>('SMTP_PASSWORD');
    if (!host || !from || !Number.isInteger(port) || port < 1 || port > 65535 || Boolean(user) !== Boolean(password) || (host === 'smtp.gmail.com' && (!user || !password))) {
      throw new ServiceUnavailableException('ระบบส่งอีเมลยังไม่พร้อมใช้งาน กรุณาลองใหม่ภายหลัง');
    }
    this.frontendUrl();
  }

  async sendResetLink(email: string, token: string): Promise<void> {
    const url = this.frontendUrl();
    const directory = url.pathname.replace(/\/$/, '');
    url.pathname = `${directory}/reset-password`;
    url.search = '';
    url.hash = `token=${token}`;
    await this.send(email, 'รีเซ็ตรหัสผ่าน InternFinder', [
      'คุณได้รับอีเมลนี้เพราะมีการขอรีเซ็ตรหัสผ่านบัญชี InternFinder ของคุณ',
      `เปิดลิงก์นี้เพื่อตั้งรหัสผ่านใหม่ (ใช้ได้ครั้งเดียวภายใน 15 นาที):\n${url.toString()}`,
      'หากคุณไม่ได้ขอรีเซ็ตรหัสผ่าน สามารถละเว้นอีเมลนี้ได้ รหัสผ่านของคุณจะยังไม่เปลี่ยน',
    ].join('\n\n'));
  }

  async sendPasswordChanged(email: string): Promise<void> {
    await this.send(email, 'รหัสผ่าน InternFinder ของคุณถูกเปลี่ยนแล้ว',
      'รหัสผ่านบัญชี InternFinder ของคุณถูกเปลี่ยนแล้ว และระบบได้ออกจากระบบทุกอุปกรณ์\n\nหากคุณไม่ได้ทำรายการนี้ ให้ขอรีเซ็ตรหัสผ่านใหม่ทันทีและติดต่อผู้ดูแลระบบ');
  }

  private frontendUrl(): URL {
    const production = this.config.get<string>('NODE_ENV') === 'production';
    const configured = this.config.get<string>('APP_WEB_URL');
    try {
      const url = new URL(configured || (production ? '' : 'http://127.0.0.1:3000'));
      if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || (production && url.protocol !== 'https:')) {
        throw new Error('Invalid reset destination');
      }
      url.search = '';
      return url;
    } catch {
      throw new ServiceUnavailableException('ระบบรีเซ็ตรหัสผ่านยังไม่พร้อมใช้งาน กรุณาลองใหม่ภายหลัง');
    }
  }

  private async send(to: string, subject: string, text: string): Promise<void> {
    this.assertConfigured();
    if (!this.transport) {
      const port = Number(this.config.get<string>('SMTP_PORT', '587'));
      const user = this.config.get<string>('SMTP_USER');
      this.transport = nodemailer.createTransport({
        host: this.config.get<string>('SMTP_HOST'),
        port,
        secure: this.config.get<string>('SMTP_SECURE', 'false') === 'true' || port === 465,
        requireTLS: this.config.get<string>('SMTP_REQUIRE_TLS', this.config.get<string>('NODE_ENV') === 'production' ? 'true' : 'false') === 'true',
        auth: user ? { user, pass: this.config.get<string>('SMTP_PASSWORD') } : undefined,
        connectionTimeout: 10_000,
        greetingTimeout: 10_000,
        socketTimeout: 15_000,
      });
    }
    await this.transport.sendMail({ from: this.config.get<string>('SMTP_FROM'), to, subject, text });
  }

  onModuleDestroy(): void {
    this.transport?.close();
  }
}
