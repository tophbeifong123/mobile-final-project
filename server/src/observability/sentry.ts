import * as Sentry from '@sentry/nestjs';

export async function initSentry(): Promise<void> {
  const dsn = process.env.SENTRY_DSN;
  if (!dsn || dsn === 'disabled') {
    return;
  }

  const profiling = await loadProfilingIntegration();
  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV,
    tracesSampleRate: 0.1,
    integrations: profiling
      ? [Sentry.nestIntegration(), profiling]
      : [Sentry.nestIntegration()],
  });
}

async function loadProfilingIntegration(): Promise<
  ReturnType<
    typeof import('@sentry/profiling-node').nodeProfilingIntegration
  > | null
> {
  try {
    const profiling = await import('@sentry/profiling-node');
    return profiling.nodeProfilingIntegration();
  } catch {
    return null;
  }
}
