import { DefaultAzureCredential } from '@azure/identity';
import { BlobServiceClient } from '@azure/storage-blob';
import { type StorageDriver } from '../storage-driver.interface.js';

export class AzureBlobStorageDriver implements StorageDriver {
  private readonly containerName: string;
  private readonly service: BlobServiceClient;

  constructor(accountName: string, containerName: string) {
    this.containerName = containerName;
    this.service = new BlobServiceClient(
      `https://${accountName}.blob.core.windows.net`,
      new DefaultAzureCredential(),
    );
  }

  async putObject(
    key: string,
    data: Buffer,
    mimeType: string,
  ): Promise<void> {
    const blob = this.service
      .getContainerClient(this.containerName)
      .getBlockBlobClient(key);
    await blob.uploadData(data, {
      blobHTTPHeaders: { blobContentType: mimeType },
    });
  }

  async getObject(key: string): Promise<Buffer | null> {
    const blob = this.service
      .getContainerClient(this.containerName)
      .getBlockBlobClient(key);
    if (!(await blob.exists())) {
      return null;
    }
    return blob.downloadToBuffer();
  }

  async deleteObject(key: string): Promise<void> {
    const blob = this.service
      .getContainerClient(this.containerName)
      .getBlockBlobClient(key);
    await blob.deleteIfExists();
  }
}
