import { AsyncLocalStorage } from 'node:async_hooks';
import { randomUUID } from 'node:crypto';
import { Injectable, type NestMiddleware } from '@nestjs/common';
import { type NextFunction, type Request, type Response } from 'express';

export const traceStorage = new AsyncLocalStorage<{ traceId: string }>();

export function currentTraceId(): string | undefined {
  return traceStorage.getStore()?.traceId;
}

@Injectable()
export class TraceMiddleware implements NestMiddleware {
  use(request: Request, response: Response, next: NextFunction): void {
    const incoming = request.header('x-trace-id');
    const traceId =
      incoming && incoming.length <= 128 ? incoming : randomUUID();
    response.setHeader('x-trace-id', traceId);
    traceStorage.run({ traceId }, () => next());
  }
}
