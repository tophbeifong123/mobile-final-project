import * as Sentry from '@sentry/nestjs';
import { type Logger, type QueryRunner } from 'typeorm';

export class SlowQueryLogger implements Logger {
  logQuery(
    _query: string,
    _parameters?: unknown[],
    _queryRunner?: QueryRunner,
  ): void {}

  logQueryError(
    _error: string | Error,
    _query: string,
    _parameters?: unknown[],
    _queryRunner?: QueryRunner,
  ): void {}

  logQuerySlow(
    time: number,
    query: string,
    _parameters?: unknown[],
    _queryRunner?: QueryRunner,
  ): void {
    if (!process.env.SENTRY_DSN || process.env.SENTRY_DSN === 'disabled') {
      return;
    }
    Sentry.addBreadcrumb({
      category: 'db',
      level: 'warning',
      message: 'slow query',
      data: {
        durationMs: time,
        statement: query.slice(0, 300),
      },
    });
  }

  logSchemaBuild(_message: string, _queryRunner?: QueryRunner): void {}

  logMigration(_message: string, _queryRunner?: QueryRunner): void {}

  log(
    _level: 'log' | 'info' | 'warn',
    _message: unknown,
    _queryRunner?: QueryRunner,
  ): void {}
}
