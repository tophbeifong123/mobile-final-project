import { type CanActivate, type ExecutionContext, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { type Request, type Response } from 'express';
import { RateLimitService } from '../rate-limit/rate-limit.service.js';

const LIMIT = 10;
const WINDOW_MS = 5 * 60_000;

@Injectable()
export class PasswordRecoveryRateLimitGuard implements CanActivate {
  constructor(private readonly rateLimit: RateLimitService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const ip = request.ip ?? request.socket.remoteAddress ?? 'unknown';
    const key = `recovery:${context.getHandler().name}:${ip}`;
    const { hits, secondsLeft } = await this.rateLimit.hit(key, WINDOW_MS);
    if (hits > LIMIT) {
      context.switchToHttp().getResponse<Response>().setHeader('Retry-After', secondsLeft);
      throw new HttpException('ส่งคำขอมากเกินไป กรุณารอ 5 นาทีแล้วลองใหม่', HttpStatus.TOO_MANY_REQUESTS);
    }
    return true;
  }
}
