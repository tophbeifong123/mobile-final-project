import { ConsoleLogger, type LogLevel } from '@nestjs/common';
import { currentTraceId } from './trace.js';

export class JsonLogger extends ConsoleLogger {
  protected printMessages(
    messages: unknown[],
    context?: string,
    logLevel?: LogLevel,
  ): void {
    for (const message of messages) {
      const line = JSON.stringify({
        timestamp: new Date().toISOString(),
        level: logLevel ?? 'log',
        context: context ?? this.context,
        message: typeof message === 'string' ? message : message,
        traceId: currentTraceId() ?? null,
      });
      process.stdout.write(`${line}\n`);
    }
  }
}
