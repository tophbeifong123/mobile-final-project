# IFND-141: Company profile on job details

Company profile persistence uses the existing migration 1759300000000. Apply the repository migrations before deploying. No additional database migration is needed for this task.

The saved profile supplies job details through a live repository join, not job-owned copies. Company address reads the existing location column and therefore remains compatible with the separately developed IFND-138 office-location feature. This task adds neither province selectors nor maps.

The student logo endpoint is GET /api/jobs/:id/company-logo. It requires authenticated student access and an open job, and reads only that company's saved storage key. Company self-service logo routes are unchanged. Missing/closed jobs or absent files return 404. Responses use private/no-store caching, nosniff, attachment disposition and a sandbox CSP, including SVG files.

Website validation accepts empty values or complete HTTP/HTTPS URLs without embedded credentials. Invalid websites return 400 before any update. Flutter validates before submitting and shows the API message if the server rejects a value.

## Verification

- Server unit tests: metadata transfer, website rejection and persistence/re-read, logo types, missing files, closed jobs, and company access rejection.
- Flutter tests: model mapping/legacy defaults, all company information on job detail, SVG logo, website errors, removal of office-photo placeholders, and reopening saved profile.
- Disposable PostgreSQL integration: real migrations and repositories, PATCH/GET profile persistence, current profile data on job detail, clearing optional values, invalid-update atomicity, logo HTTP role/status checks, and Swagger fields/routes.

To run the integration test, start an isolated local PostgreSQL cluster using trust authentication and user postgres on a dedicated port above 5432. Do not point it at an existing application/production database. The script creates and drops only its own randomly named test database.

```powershell
cd server
npm run build
$env:COMPANY_PROFILE_INTEGRATION_PORT = '5446'
node --test test/company-job-profile.integration.mjs
```
