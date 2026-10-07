import { type MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { postgresSslConfig } from './database/postgres-ssl.js';
import { HealthController } from './health/health.controller.js';
import { AllExceptionsFilter } from './observability/all-exceptions.filter.js';
import { SlowQueryLogger } from './observability/slow-query.logger.js';
import { TraceMiddleware } from './observability/trace.js';
import { ApplicationsModule } from './applications/applications.module.js';
import { AuthModule } from './auth/auth.module.js';
import { CompaniesModule } from './companies/companies.module.js';
import { JobsModule } from './jobs/jobs.module.js';
import { NotificationsModule } from './notifications/notifications.module.js';
import { ProvincesModule } from './provinces/provinces.module.js';
import { UniversitiesModule } from './universities/universities.module.js';
import { StorageModule } from './storage/storage.module.js';
import { StudentsModule } from './students/students.module.js';
import { MajorsModule } from './majors/majors.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        host: config.get<string>('DATABASE_HOST', 'localhost'),
        port: Number(config.get<string>('DATABASE_PORT', '5432')),
        username: config.get<string>('DATABASE_USER', 'postgres'),
        password: config.get<string>('DATABASE_PASSWORD', 'postgres'),
        database: config.get<string>('DATABASE_NAME', 'mobile_project_db'),
        ssl: postgresSslConfig(),
        autoLoadEntities: true,
        synchronize: false,
        maxQueryExecutionTime: 500,
        logger: new SlowQueryLogger(),
      }),
    }),
    StorageModule,
    AuthModule,
    StudentsModule,
    MajorsModule,
    JobsModule,
    ApplicationsModule,
    NotificationsModule,
    ProvincesModule,
    UniversitiesModule,
    CompaniesModule,
  ],
  controllers: [AppController, HealthController],
  providers: [
    AppService,
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(TraceMiddleware).forRoutes('*');
  }
}
