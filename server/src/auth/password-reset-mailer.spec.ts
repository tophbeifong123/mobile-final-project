import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PasswordResetMailer } from './password-reset-mailer.js';

const transport = vi.hoisted(() => ({
  sendMail: vi.fn(),
  close: vi.fn(),
  createTransport: vi.fn(),
}));
vi.mock('nodemailer', () => ({
  default: { createTransport: transport.createTransport },
}));

describe('PasswordResetMailer', () => {
  const gmail = {
    SMTP_HOST: 'smtp.gmail.com',
    SMTP_PORT: '587',
    SMTP_FROM: 'InternFinder <sender@gmail.com>',
    SMTP_USER: 'sender@gmail.com',
    SMTP_PASSWORD: 'test-app-password',
    SMTP_REQUIRE_TLS: 'true',
    APP_WEB_URL: 'https://internfinder.example/app/?discard=1#old-route',
  };

  beforeEach(() => {
    vi.resetAllMocks();
    transport.createTransport.mockReturnValue({
      sendMail: transport.sendMail,
      close: transport.close,
    });
    transport.sendMail.mockResolvedValue({});
  });

  it('uses Gmail STARTTLS and the configured sender without network calls', async () => {
    const mailer = new PasswordResetMailer(new ConfigService(gmail));

    await mailer.sendResetLink('student@example.com', 'a'.repeat(64));

    expect(transport.createTransport).toHaveBeenCalledWith(
      expect.objectContaining({
        host: 'smtp.gmail.com',
        port: 587,
        secure: false,
        requireTLS: true,
        auth: { user: 'sender@gmail.com', pass: 'test-app-password' },
      }),
    );
    expect(transport.sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        from: gmail.SMTP_FROM,
        to: 'student@example.com',
        text: expect.stringContaining(
          `https://internfinder.example/app/reset-password#token=${'a'.repeat(64)}`,
        ),
      }),
    );
    expect(transport.sendMail.mock.calls[0][0].text).not.toContain('discard=1');
    expect(transport.sendMail.mock.calls[0][0].text).not.toContain('?token=');
  });

  it('uses implicit TLS for Gmail port 465 and reuses and closes its transport', async () => {
    const mailer = new PasswordResetMailer(
      new ConfigService({ ...gmail, SMTP_PORT: '465' }),
    );

    await mailer.sendResetLink('student@example.com', 'b'.repeat(64));
    await mailer.sendPasswordChanged('student@example.com');
    mailer.onModuleDestroy();

    expect(transport.createTransport).toHaveBeenCalledTimes(1);
    expect(transport.createTransport).toHaveBeenCalledWith(
      expect.objectContaining({ secure: true, port: 465 }),
    );
    expect(transport.sendMail).toHaveBeenCalledTimes(2);
    expect(transport.sendMail.mock.calls[1][0].text).not.toContain(
      'reset-password?token=',
    );
    expect(transport.close).toHaveBeenCalledOnce();
  });

  it.each([
    { SMTP_HOST: '' },
    { SMTP_FROM: '' },
    { SMTP_PORT: '0' },
    { SMTP_PORT: '65536' },
    { SMTP_PORT: '587.5' },
    { SMTP_PORT: 'invalid' },
    { SMTP_PASSWORD: '' },
    { SMTP_USER: '' },
    { SMTP_USER: '', SMTP_PASSWORD: '' },
  ])('rejects incomplete or invalid SMTP settings: %j', (invalid) => {
    const mailer = new PasswordResetMailer(
      new ConfigService({ ...gmail, ...invalid }),
    );

    expect(() => mailer.assertConfigured()).toThrow(
      ServiceUnavailableException,
    );
    expect(transport.createTransport).not.toHaveBeenCalled();
  });

  it.each([
    'javascript:alert(1)',
    'https://user:secret@example.com',
    'not-a-url',
  ])('rejects an unsafe reset destination %s', (url) => {
    const mailer = new PasswordResetMailer(
      new ConfigService({ ...gmail, APP_WEB_URL: url }),
    );

    expect(() => mailer.assertConfigured()).toThrow(
      ServiceUnavailableException,
    );
  });

  it.each(['', 'http://internfinder.example'])(
    'requires an explicit HTTPS destination in production: %s',
    (url) => {
      const mailer = new PasswordResetMailer(
        new ConfigService({
          ...gmail,
          NODE_ENV: 'production',
          APP_WEB_URL: url,
        }),
      );

      expect(() => mailer.assertConfigured()).toThrow(
        ServiceUnavailableException,
      );
    },
  );
});
