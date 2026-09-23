import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LocalStorageDriver } from './drivers/local-storage.driver.js';
import { S3StorageDriver } from './drivers/s3-storage.driver.js';
import { STORAGE_DRIVER } from './storage-driver.interface.js';
import { StorageService } from './storage.service.js';

@Module({
  providers: [
    {
      provide: STORAGE_DRIVER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const driverType = config
          .get<string>('STORAGE_DRIVER', 'local')
          .toLowerCase();

        if (driverType === 's3' || driverType === 'minio') {
          return new S3StorageDriver({
            endpoint: config.get<string>('S3_ENDPOINT', 'http://minio:9000'),
            region: config.get<string>('S3_REGION', 'us-east-1'),
            bucket: config.get<string>('S3_BUCKET', 'internfinder'),
            accessKeyId: config.get<string>('S3_ACCESS_KEY', 'minioadmin'),
            secretAccessKey: config.get<string>('S3_SECRET_KEY', 'minioadmin'),
            forcePathStyle:
              config.get<string>('S3_FORCE_PATH_STYLE', 'true') === 'true',
          });
        }

        const storageDir = config.get<string>('STORAGE_DIR', './uploads');
        return new LocalStorageDriver(storageDir);
      },
    },
    StorageService,
  ],
  exports: [StorageService],
})
export class StorageModule {}
