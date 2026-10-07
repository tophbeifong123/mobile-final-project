import {
  RequestMethod,
  ValidationPipe,
  type INestApplication,
} from '@nestjs/common';

export function configureApp(app: INestApplication): void {
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
