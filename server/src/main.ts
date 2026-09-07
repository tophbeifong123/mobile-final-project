import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS for mobile & web clients
  app.enableCors();

  // Set global API prefix
  app.setGlobalPrefix('api');

  // Setup Swagger OpenAPI Documentation
  const config = new DocumentBuilder()
    .setTitle('Mobile Final Project API')
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

