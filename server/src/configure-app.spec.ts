import { type INestApplication } from '@nestjs/common';
import { configureApp } from './configure-app.js';

describe('configureApp', () => {
  function app() {
    const express = { set: vi.fn() };
    const nest = {
      getHttpAdapter: () => ({ getInstance: () => express }),
      enableCors: vi.fn(),
      setGlobalPrefix: vi.fn(),
      useGlobalPipes: vi.fn(),
    };
    return { express, nest: nest as unknown as INestApplication };
  }

  it('trusts the configured number of proxy hops', () => {
    const { express, nest } = app();
    configureApp(nest, { TRUST_PROXY_HOPS: '1' });
    expect(express.set).toHaveBeenCalledWith('trust proxy', 1);
  });

  it('does not trust forwarded headers without a configured proxy', () => {
    const { express, nest } = app();
    configureApp(nest, {});
    configureApp(nest, { TRUST_PROXY_HOPS: 'yes' });
    expect(express.set).not.toHaveBeenCalled();
  });
});
