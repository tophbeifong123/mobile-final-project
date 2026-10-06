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
- `pendingApplicantCount` on each company job uses the same pending statuses.
- The Flutter page uses CompanyTopBar, Neo styling, retry, and pull-to-refresh.
  Counts are read-only. Up to five jobs with pending applications open that
  job's applicant list. Up to five drafts, or open jobs due within 7 days or
  already overdue, open the edit form. A company with no jobs gets one create
  button. A company with jobs but nothing to do sees that there is nothing to
  review. Returning to the page reloads the summary and the job list.
- No new tables, applicant-name list, or company notifications.

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
