# SWP-HRMS

Standalone Django HRMS extracted from `cpaswp/swp-homes`, source branch `feature/hrms-foundation`.

## Scope
Includes the HR application, its eight existing migrations, HR templates/static assets, employee administration, attendance, leave/approvals, payroll screens, recruitment interviews, talent planning, attachments, and employee fund/excellence screens.

The application configuration is standalone and does not install the property, leasing, or accounting apps. Company membership lookup was removed from the employee ID-card view; the card currently has no company branding context.

## Local setup
```bash
python -m venv .venv
# Windows: .venv\\Scripts\\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

The default local database is SQLite. Set `DATABASE_URL` to use PostgreSQL/Neon.

## Neon configuration
1. Create a PostgreSQL project in Neon and copy its connection string (pooled connection string recommended for web deployments).
2. Add `DATABASE_URL` to the deployment platform's environment/secrets. Do not commit the real value.
3. Set `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=False`, `DJANGO_ALLOWED_HOSTS`, and `DJANGO_CSRF_TRUSTED_ORIGINS`.
4. Run `python manage.py migrate --noinput` once as a release step, then deploy the web process.
5. Check `/health/`, login, static assets, and application logs.

## Verification status
GitHub Actions is configured to run Django system checks, migration drift checks, and pytest. Do not treat this repository as production-ready until those checks pass in GitHub Actions and PostgreSQL/Neon smoke tests are completed.

## Known limitations
- No live Neon database was provisioned or connected as part of this repository transfer.
- No automated tenant isolation or company-scoped authorization was added by this extraction.
- Hardware attendance device integration and liveness/face verification must not be considered implemented without separate validated work.
- Uploaded files use local filesystem storage; configure durable object storage before production.
- Payroll/legal rules require validation for the intended jurisdiction before production use.
