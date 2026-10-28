import os
from pathlib import Path
from urllib.parse import urlparse

import dj_database_url
from django.core.exceptions import ImproperlyConfigured

BASE_DIR = Path(__file__).resolve().parent.parent
DEBUG = os.getenv("DJANGO_DEBUG", "False").lower() in {"1", "true", "yes", "on"}

SECRET_KEY = os.getenv("DJANGO_SECRET_KEY", "").strip()
if DEBUG and not SECRET_KEY:
    SECRET_KEY = "dev-only-insecure-key-for-local-development"
elif not DEBUG:
    # Reject placeholders and weak values before Django starts serving requests.
    weak_key_values = {
        "dev-only-change-this-key-before-deployment",
        "dev-only-insecure-key-for-local-development",
        "change-me",
        "changeme",
        "secret",
        "19841984",
    }
    if len(SECRET_KEY) < 50 or SECRET_KEY.lower() in weak_key_values:
        raise ImproperlyConfigured(
            "Set DJANGO_SECRET_KEY to a unique random secret of at least 50 characters in production."
        )

raw_allowed_hosts = os.getenv("DJANGO_ALLOWED_HOSTS", "").strip()
if DEBUG:
    if not raw_allowed_hosts:
        raw_allowed_hosts = "localhost,127.0.0.1,testserver"
else:
    if not raw_allowed_hosts:
        raise ImproperlyConfigured(
            "Set DJANGO_ALLOWED_HOSTS to the exact deployment hostname(s), without scheme or path."
        )
ALLOWED_HOSTS = [h.strip() for h in raw_allowed_hosts.split(",") if h.strip()]
if not DEBUG and (
    not ALLOWED_HOSTS
    or "*" in ALLOWED_HOSTS
    or any("://" in host or "/" in host or " " in host for host in ALLOWED_HOSTS)
):
    raise ImproperlyConfigured(
        "Production DJANGO_ALLOWED_HOSTS must contain explicit hostnames only, without scheme, path, spaces, or '*'."
    )
CSRF_TRUSTED_ORIGINS = [
    u.strip() for u in os.getenv("DJANGO_CSRF_TRUSTED_ORIGINS", "").split(",") if u.strip()
]
if not DEBUG:
    for origin in CSRF_TRUSTED_ORIGINS:
        if not origin.startswith(("https://", "http://")) or not urlparse(origin).netloc:
            raise ImproperlyConfigured(
                "DJANGO_CSRF_TRUSTED_ORIGINS must contain full origins such as https://hr.example.com."
            )

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "hr.apps.HrConfig",
]
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.locale.LocaleMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]
ROOT_URLCONF = "config.urls"
TEMPLATES = [{
    "BACKEND": "django.template.backends.django.DjangoTemplates",
    "DIRS": [BASE_DIR / "templates"],
    "APP_DIRS": True,
    "OPTIONS": {"context_processors": [
        "django.template.context_processors.debug",
        "django.template.context_processors.request",
        "django.contrib.auth.context_processors.auth",
        "django.contrib.messages.context_processors.messages",
        "django.template.context_processors.i18n",
    ]},
}]
WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

DATABASE_URL = os.getenv("DATABASE_URL", "").strip()
if not DEBUG and not DATABASE_URL:
    raise ImproperlyConfigured(
        "DATABASE_URL is required in production; refusing to start with an ephemeral/local SQLite database."
    )
if not DEBUG and urlparse(DATABASE_URL).scheme not in {"postgres", "postgresql", "postgresql+psycopg"}:
    raise ImproperlyConfigured(
        "Production DATABASE_URL must point to PostgreSQL/Neon; SQLite is development-only."
    )
if DATABASE_URL:
    DATABASES = {
        "default": dj_database_url.parse(
            DATABASE_URL,
            conn_max_age=int(os.getenv("DJANGO_DB_CONN_MAX_AGE", "60")),
            ssl_require=not DEBUG,
        )
    }
else:
    DATABASES = {"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": BASE_DIR / "db.sqlite3"}}

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]
LANGUAGE_CODE = "ar"
LANGUAGES = [("ar", "العربية"), ("en", "English")]
TIME_ZONE = os.getenv("DJANGO_TIME_ZONE", "Africa/Cairo")
USE_I18N = True
USE_TZ = True
STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = [BASE_DIR / "static"] if (BASE_DIR / "static").exists() else []
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"
        if DEBUG else "whitenoise.storage.CompressedManifestStaticFilesStorage"
    },
}
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
LOGIN_URL = "login"
LOGIN_REDIRECT_URL = "hr:dashboard"
LOGOUT_REDIRECT_URL = "login"
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG

# Production security defaults; override only when the deployment architecture requires it.
SECURE_SSL_REDIRECT = os.getenv("DJANGO_SECURE_SSL_REDIRECT", str(not DEBUG)).lower() in {"1", "true", "yes", "on"}
SECURE_HSTS_SECONDS = int(os.getenv("DJANGO_SECURE_HSTS_SECONDS", "31536000" if not DEBUG else "0"))
SECURE_HSTS_INCLUDE_SUBDOMAINS = os.getenv("DJANGO_SECURE_HSTS_INCLUDE_SUBDOMAINS", "False").lower() in {"1", "true", "yes", "on"}
SECURE_HSTS_PRELOAD = os.getenv("DJANGO_SECURE_HSTS_PRELOAD", "False").lower() in {"1", "true", "yes", "on"}
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
