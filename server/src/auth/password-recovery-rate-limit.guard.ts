import { type CanActivate, type ExecutionContext, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { type Request, type Response } from 'express';

@Injectable()
export class PasswordRecoveryRateLimitGuard implements CanActivate {
  private readonly attempts = new Map<string, { count: number; until: number }>();

  canActivate(context: ExecutionContext): boolean {
    const now = Date.now();
    for (const [key, attempt] of this.attempts) {
      if (attempt.until <= now) this.attempts.delete(key);
    }
    const request = context.switchToHttp().getRequest<Request>();
    const key = `${context.getHandler().name}:${request.ip ?? request.socket.remoteAddress ?? 'unknown'}`;
    const attempt = this.attempts.get(key);
    if ((attempt && attempt.count >= 10) || (!attempt && this.attempts.size >= 10_000)) {
      context.switchToHttp().getResponse<Response>().setHeader('Retry-After', Math.ceil(((attempt?.until ?? now + 5 * 60_000) - now) / 1000));
      throw new HttpException('ส่งคำขอมากเกินไป กรุณารอ 5 นาทีแล้วลองใหม่', HttpStatus.TOO_MANY_REQUESTS);
    }
    this.attempts.set(key, {
      count: (attempt?.count ?? 0) + 1,
      until: attempt?.until ?? now + 5 * 60_000,
    });
    return true;
  }
}
