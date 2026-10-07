import {
  RequestMethod,
  ValidationPipe,
  type INestApplication,
} from '@nestjs/common';

export function configureApp(
  app: INestApplication,
  env: NodeJS.ProcessEnv = process.env,
): void {
  const proxyHops = Number(env.TRUST_PROXY_HOPS ?? 0);
  if (Number.isInteger(proxyHops) && proxyHops > 0) {
    // Only behind a known ingress; otherwise clients could spoof X-Forwarded-For.
    app.getHttpAdapter().getInstance().set('trust proxy', proxyHops);
  }
  app.enableCors({ exposedHeaders: ['Retry-After'] });
  app.setGlobalPrefix('api', {
    exclude: [{ path: 'reset-password', method: RequestMethod.GET }],
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
}
