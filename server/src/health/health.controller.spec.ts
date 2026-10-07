import { HealthController } from './health.controller.js';

describe('HealthController', () => {
  it('reports the process as live without touching the database', () => {
    const controller = new HealthController({ query: async () => [] } as never);
    expect(controller.live()).toEqual({ status: 'ok' });
  });

  it('is ready only after PostgreSQL answers', async () => {
    const query = vi.fn().mockResolvedValue([{ '?column?': 1 }]);
    const controller = new HealthController({ query } as never);
    await expect(controller.ready()).resolves.toEqual({ status: 'ok' });
    expect(query).toHaveBeenCalledWith('SELECT 1');
  });
});
