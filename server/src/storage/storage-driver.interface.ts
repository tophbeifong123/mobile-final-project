export const STORAGE_DRIVER = Symbol('STORAGE_DRIVER');

export interface StorageDriver {
  putObject(key: string, data: Buffer, mimeType: string): Promise<void>;
  getObject(key: string): Promise<Buffer | null>;
  deleteObject(key: string): Promise<void>;
}
