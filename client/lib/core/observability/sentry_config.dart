const sentryDsn = String.fromEnvironment('SENTRY_DSN');

bool get sentryEnabled => sentryDsn.isNotEmpty;
