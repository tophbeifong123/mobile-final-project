# Company dashboard (IFND-142)

`GET /api/companies/me/dashboard` requires company authentication. Its response
contains `totalJobs`, `openJobs`, `totalApplicants`, and `pendingApplicants`.
The Swagger contract is available at `/api/docs`.

- All counts belong to the authenticated company's profile ID.
- Total jobs include every status; open jobs include only `open`.
- Applicant counts count applications, not distinct students or timeline events.
- CompaniesService defines pending as `submitted` or `reviewing`. Closed jobs'
  applications remain included; `accepted` and `rejected` are not pending.
- No jobs means four zero counts. Database errors must not become zero counts.
- The Flutter page uses CompanyTopBar, Neo styling, retry/pull-to-refresh, and
  refreshes when returning from job management or creation. Every statistic
  opens job management; the create button opens the new-job form.
- No new tables, shortlist, recent applicants, or company notifications.

## Verification

Server unit tests cover service status selection, role checks, zero counts,
error propagation, and query scoping. Flutter tests cover values, retry, all
navigation actions on empty data, and fresh counts after returning.

For PostgreSQL integration, first start a **separate disposable local cluster**
with user `postgres` and trust authentication (never the running app database).
The script creates a unique test database and drops only that database in its
cleanup. From `server/`:

```powershell
npm run build
$env:DASHBOARD_INTEGRATION_PORT = '5447'
node --test test/company-dashboard.integration.mjs
```

This checks real counts across companies, open/closed/draft jobs, all four
application statuses, empty data, live updates, access control, and Swagger.
