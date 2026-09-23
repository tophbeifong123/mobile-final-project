import { S3StorageDriver } from './s3-storage.driver.js';

describe('S3StorageDriver', () => {
  it('instantiates client with provided configuration', () => {
    const driver = new S3StorageDriver({
      endpoint: 'http://localhost:9000',
      region: 'us-east-1',
      bucket: 'test-bucket',
      accessKeyId: 'minioadmin',
      secretAccessKey: 'minioadmin',
      forcePathStyle: true,
    });

    expect(driver).toBeDefined();
  });
});
