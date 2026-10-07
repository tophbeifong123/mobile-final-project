import {
  type ArgumentsHost,
  Catch,
  type ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import * as Sentry from '@sentry/nestjs';
import { type Request, type Response } from 'express';
import { currentTraceId } from './trace.js';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const response = http.getResponse<Response>();
    const request = http.getRequest<Request>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    if (status >= 500 && process.env.SENTRY_DSN && process.env.SENTRY_DSN !== 'disabled') {
      Sentry.captureException(exception, {
        extra: {
          method: request.method,
          path: request.path,
          traceId: currentTraceId() ?? null,
        },
      });
    }

    const payload =
      exception instanceof HttpException
        ? exception.getResponse()
        : { statusCode: status, message: 'Internal server error' };
    response.status(status).json(payload);
  }
}
