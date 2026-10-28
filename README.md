# SWP-HRMS

Standalone Django HRMS extracted from `cpaswp/swp-homes`, source branch `feature/hrms-foundation`.

## Scope
Includes the HR application, its migrations, HR templates/static assets, employee administration, attendance, leave/approvals, payroll screens, recruitment interviews, talent planning, attachments, and employee fund/excellence screens.

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

## Production configuration
Production startup intentionally fails closed unless all critical configuration is present:
- `DATABASE_URL`: PostgreSQL connection string; a pooled Neon connection is recommended for web workloads.
- `DJANGO_SECRET_KEY`: unique random secret with at least 50 characters. Never use a short password, a predictable value, or commit it.
- `DJANGO_DEBUG=False`.
- `DJANGO_ALLOWED_HOSTS`: comma-separated exact hostnames only, without scheme/path and without `*`.
- `DJANGO_CSRF_TRUSTED_ORIGINS`: comma-separated full origins such as `https://hr.example.com` when needed by the deployment's HTTPS/proxy setup.
- `DJANGO_TIME_ZONE=Africa/Cairo`.

Never commit real secrets. If a database URL or password was pasted into a chat, log, issue, or repository, rotate it and update the deployment secret.

## Deployment
This repository is a Django/WSGI application. It cannot run directly as a Cloudflare Worker: Workers execute JavaScript/TypeScript rather than Django's Python WSGI runtime. Moving it to Workers requires a real application port (routes, authentication, permissions, data access, migrations, and file storage), not merely changing a deployment command.

For a Django-capable host:
1. Build with `pip install -r requirements.txt && python manage.py collectstatic --noinput`.
2. Run migrations as a controlled release step: `python manage.py migrate --noinput`.
3. Start the web process with `gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers 1 --timeout 120` on a small/free instance.
4. Set the production environment variables above after the platform assigns the public hostname.
5. Check `/health/`, login, static assets, database writes, and application logs before real use.

Avoid running migrations concurrently from multiple application instances. Do not use a free ephemeral local filesystem for employee attachments; configure durable object storage before production.

## Verification status
GitHub Actions runs Django system checks, migration drift checks, and pytest. Do not treat this repository as production-ready until those checks pass and PostgreSQL/Neon smoke tests are completed.

## Known limitations
- No live Neon database was provisioned or connected as part of this repository transfer.
- No automated tenant isolation or company-scoped authorization was added by this extraction.
- Hardware attendance device integration and liveness/face verification must not be considered implemented without separate validated work.
- Uploaded files use local filesystem storage until durable object storage is configured.
- Payroll/legal rules require validation for the intended jurisdiction before production use.
