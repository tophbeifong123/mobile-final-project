import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LocalStorageDriver } from './drivers/local-storage.driver.js';
import { STORAGE_DRIVER } from './storage-driver.interface.js';
import { StorageService } from './storage.service.js';

@Module({
  providers: [
    {
      provide: STORAGE_DRIVER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const storageDir = config.get<string>('STORAGE_DIR', './uploads');
        return new LocalStorageDriver(storageDir);
      },
    },
    StorageService,
  ],
  exports: [StorageService],
})
export class StorageModule {}
