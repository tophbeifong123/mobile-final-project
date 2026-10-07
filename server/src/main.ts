import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module.js';
import { configureApp } from './configure-app.js';
import { JsonLogger } from './observability/json-logger.js';
import { initSentry } from './observability/sentry.js';

async function bootstrap() {
  await initSentry();
  const app = await NestFactory.create(
    AppModule,
    process.env.LOG_FORMAT === 'json' ? { logger: new JsonLogger() } : {},
  );
  configureApp(app);

  const config = new DocumentBuilder()
    .setTitle('InternFinder API')
    .setDescription('Backend REST API service for Flutter Mobile Application')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`🚀 Server running on http://localhost:${port}/api`);
  console.log(`📑 Swagger Documentation available at http://localhost:${port}/api/docs`);
}
await bootstrap();

