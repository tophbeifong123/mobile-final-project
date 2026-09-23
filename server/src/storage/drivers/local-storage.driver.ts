import { promises as fs } from 'node:fs';
import * as path from 'node:path';
import { type StorageDriver } from '../storage-driver.interface.js';

export class LocalStorageDriver implements StorageDriver {
  constructor(private readonly baseDir: string = './uploads') {}

  private resolveSafePath(key: string): string {
    const sanitizedKey = path.normalize(key).replace(/^(\.\.(\/|\\|$))+/, '');
    return path.resolve(this.baseDir, sanitizedKey);
  }

  async putObject(
    key: string,
    data: Buffer,
    _mimeType: string,
  ): Promise<void> {
    const fullPath = this.resolveSafePath(key);
    await fs.mkdir(path.dirname(fullPath), { recursive: true });
    await fs.writeFile(fullPath, data);
  }

  async getObject(key: string): Promise<Buffer | null> {
    const fullPath = this.resolveSafePath(key);
    try {
      return await fs.readFile(fullPath);
    } catch {
      return null;
    }
  }

  async deleteObject(key: string): Promise<void> {
    const fullPath = this.resolveSafePath(key);
    try {
      await fs.unlink(fullPath);
    } catch {
      // ignore if file doesn't exist
    }
  }
}
