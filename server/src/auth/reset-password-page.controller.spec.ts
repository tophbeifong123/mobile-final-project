import { Test } from '@nestjs/testing';
import { configureApp } from '../configure-app.js';
import { ResetPasswordPageController } from './reset-password-page.controller.js';
import { renderResetPasswordPage } from './reset-password.page.js';

describe('ResetPasswordPageController', () => {
  it('serves the reset form outside the API prefix and ignores query tokens', async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [ResetPasswordPageController],
    }).compile();
    const app = moduleRef.createNestApplication();
    configureApp(app);
    await app.listen(0, '127.0.0.1');
    try {
      const origin = await app.getUrl();
      const page = await fetch(
        `${origin}/reset-password?token=not-in-the-page`,
      );
      expect(page.status).toBe(200);
      expect(page.headers.get('referrer-policy')).toBe('no-referrer');
      expect(page.headers.get('cache-control')).toContain('no-store');
      const policy = page.headers.get('content-security-policy') ?? '';
      expect(policy).toContain("default-src 'none'");
      expect(policy).toMatch(/script-src 'nonce-[A-Za-z0-9_-]{22}'/);
      const html = await page.text();
      expect(html).toContain('ตั้งรหัสผ่านใหม่');
      expect(html).toContain('location.hash');
      expect(html).not.toContain('not-in-the-page');
      expect(html).not.toContain('location.search');
      expect((await fetch(`${origin}/api/reset-password`)).status).toBe(404);
    } finally {
      await app.close();
    }
  });

  it('rejects a nonce that could break out of the page', () => {
    expect(() => renderResetPasswordPage('"><script>')).toThrow(
      'Invalid reset page nonce',
    );
  });
});
