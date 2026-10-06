import { DataSource } from 'typeorm';
import { ApplicationStatus } from '../applications/application-status.js';
import { Application } from '../applications/entities/application.entity.js';
import { Job } from '../jobs/entities/job.entity.js';
import { JobStatus } from '../jobs/job-enums.js';
import { CompaniesRepository } from './companies.repository.js';

describe('company dashboard queries', () => {
  it('scopes every count to the company and applies service-provided pending statuses', async () => {
    const query = () => {
      const builder = { innerJoin: vi.fn(), where: vi.fn(), andWhere: vi.fn(), getCount: vi.fn() };
      builder.innerJoin.mockReturnValue(builder);
      builder.where.mockReturnValue(builder);
      builder.andWhere.mockReturnValue(builder);
      return builder;
    };
    const total = query();
    total.getCount.mockResolvedValue(12);
    const pending = query();
    pending.getCount.mockResolvedValue(7);
    const jobs = { count: vi.fn().mockResolvedValueOnce(5).mockResolvedValueOnce(3) };
    const applications = { createQueryBuilder: vi.fn().mockReturnValueOnce(total).mockReturnValueOnce(pending) };
    const source = { getRepository: vi.fn((entity) => entity === Job ? jobs : applications) };
    const repository = new CompaniesRepository(source as unknown as DataSource);
    const statuses = [ApplicationStatus.Submitted, ApplicationStatus.Reviewing];

    expect(await repository.getDashboardSummary('company-1', statuses)).toEqual({
      totalJobs: 5, openJobs: 3, totalApplicants: 12, pendingApplicants: 7,
    });
    expect(source.getRepository).toHaveBeenCalledWith(Application);
    expect(jobs.count).toHaveBeenNthCalledWith(1, { where: { companyId: 'company-1' } });
    expect(jobs.count).toHaveBeenNthCalledWith(2, { where: { companyId: 'company-1', status: JobStatus.Open } });
    for (const builder of [total, pending]) {
      expect(builder.innerJoin).toHaveBeenCalledWith(Job, 'job', 'job.id = app.jobId');
      expect(builder.where).toHaveBeenCalledWith('job.companyId = :companyId', { companyId: 'company-1' });
    }
    expect(total.andWhere).not.toHaveBeenCalled();
    expect(pending.andWhere).toHaveBeenCalledWith('app.status IN (:...pendingStatuses)', { pendingStatuses: statuses });
  });
});
