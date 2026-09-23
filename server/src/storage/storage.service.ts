import { Inject, Injectable } from '@nestjs/common';
import {
  STORAGE_DRIVER,
  type StorageDriver,
} from './storage-driver.interface.js';

@Injectable()
export class StorageService {
  constructor(
    @Inject(STORAGE_DRIVER) private readonly driver: StorageDriver,
  ) {}

  async put(key: string, buffer: Buffer, mimeType: string): Promise<string> {
    await this.driver.putObject(key, buffer, mimeType);
    return key;
  }

  async get(key: string): Promise<Buffer | null> {
    return this.driver.getObject(key);
  }

  async delete(key: string): Promise<void> {
    await this.driver.deleteObject(key);
  }
}
