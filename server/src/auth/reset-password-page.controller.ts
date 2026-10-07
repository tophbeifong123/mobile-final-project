import { Controller, Get, Res } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import { randomBytes } from 'node:crypto';
import type { Response } from 'express';
import { renderResetPasswordPage } from './reset-password.page.js';

@ApiExcludeController()
@Controller('reset-password')
export class ResetPasswordPageController {
  @Get()
  page(@Res() response: Response): void {
    const nonce = randomBytes(16).toString('base64url');
    response
      .status(200)
      .set({
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-store',
        'Referrer-Policy': 'no-referrer',
        'X-Content-Type-Options': 'nosniff',
        'Content-Security-Policy': [
          "default-src 'none'",
          `script-src 'nonce-${nonce}'`,
          `style-src 'nonce-${nonce}'`,
          "connect-src 'self'",
          "base-uri 'none'",
          "form-action 'self'",
          "frame-ancestors 'none'",
        ].join('; '),
      })
      .send(renderResetPasswordPage(nonce));
  }
}
