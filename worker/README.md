# HRMS Cloudflare Worker migration — milestone 1

This is a parallel Worker implementation. The Django application remains untouched and is the source of truth until feature parity and acceptance tests are complete. The ERP repository and its deployment are not modified.

## Safety boundary
- Only use a dedicated PostgreSQL database/project for HRMS, with a database name containing `hrms`.
- Never reuse ERP's Neon database, Hyperdrive binding, credentials, or migrations.
- SQL objects are prefixed `hrms_`; the migration is additive and is not a data migration from Django yet.
- Do not configure production secrets in source control. `HRMS_API_TOKEN` must be a random secret at least 32 characters long.
- The current API uses a single bearer-token gate as a migration scaffold, not a substitute for the ERP's final user/session/role authorization. Do not expose employee/payroll endpoints publicly until identity and role mapping are implemented.

## Local setup
1. Install Node.js 20+.
2. `cd worker && npm install`
3. Copy `.dev.vars.example` to `.dev.vars` and replace placeholders locally.
4. `npm test` and `npm run typecheck`.
5. Validate SQL migration files with `npm run check:migrations`.
6. Start locally with `npm run dev`.

## Database migration
Inspect and apply `migrations/0001_hrms_core.sql`, `migrations/0002_hrms_operations.sql`, and `migrations/0003_hrms_approvals_recruitment.sql`, and `migrations/0004_hrms_model_parity.sql`, and `migrations/0005_hrms_payroll_insurance_performance.sql`, and `migrations/0006_hrms_supporting_modules.sql`, and `migrations/0007_hrms_field_parity_corrections.sql` in order, only to the separately provisioned HRMS test database. Do not run it against ERP. Do not store connection strings in Git. Deployment binding `HRMS_DB` must be a Hyperdrive configuration built for that dedicated database. To apply the numbered SQL migrations, set `HRMS_DATABASE_URL` temporarily in your local shell to the dedicated HRMS test database URL and run `npm run migrate`; the runner rejects database names without `hrms` or with `erp`, verifies the connected database name, and skips versions already recorded. Never run it against production or ERP.

## Current milestone
Implemented: Worker entry point, health endpoint, authenticated read-only department/employee list endpoints, bounded pagination, namespaced PostgreSQL schema for the core employee directory plus attendance, leave balances/requests, payroll periods/items, approval steps, recruitment candidates, employee document metadata, skills, mission requests, attendance exceptions, department manager links, insurance records, payroll components and deductions, salary changes, KPIs, performance reviews, and supporting schemas for training, compliance, contracts, advances, custody, benefits, recruitment interviews, career development, succession, and employee funds; read-only department, employee, attendance, and leave-request endpoints; bounded pagination (limit 1–100, offset 0–1,000,000 with malformed values rejected); and initial security tests.

Not yet ported: runtime verification of exact field-by-field parity against every Django model, Django admin/session login, write workflows and approval actions, geofence validation and attendance rules, leave approval/balance accrual logic, payroll calculations/tax/insurance and approvals, recruitment, employee documents/object storage, exports, and role-based permissions. These are explicit follow-on milestones; this scaffold must not be described as a feature-complete HRMS.


## Migration verification limits
`npm run check:migrations` checks ordering, migration-ledger entries, HRMS table prefixes, and that each `ALTER TABLE` target is declared in the migration set. It is a static guard only: the migrations still require execution and repeat-run testing against a disposable, dedicated HRMS PostgreSQL test database before any deployment. Schema parity with Django models is still in progress; this Worker is not production-ready.
