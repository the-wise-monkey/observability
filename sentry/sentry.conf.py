# =========================================
# Sentry Configuration
# =========================================
#
# This file configures Sentry for the observability stack with:
# - PostgreSQL database backend
# - Redis for caching and queue management
# - Email notifications (configurable)
# - File storage for attachments
# - Security and performance settings
#
# =========================================

import os
import os.path

CONF_ROOT = os.path.dirname(__file__)

# Database configuration
DATABASES = {
    'default': {
        'ENGINE': 'sentry.db.postgres',
        'NAME': os.environ.get('SENTRY_DB_NAME', 'sentry'),
        'USER': os.environ.get('SENTRY_DB_USER', 'sentry'),
        'PASSWORD': os.environ.get('SENTRY_DB_PASSWORD', 'sentry'),
        'HOST': os.environ.get('SENTRY_POSTGRES_HOST', 'sentry-postgres'),
        'PORT': os.environ.get('SENTRY_POSTGRES_PORT', '5432'),
    }
}

# Redis configuration
SENTRY_REDIS_OPTIONS = {
    'hosts': {
        0: {
            'host': os.environ.get('SENTRY_REDIS_HOST', 'sentry-redis'),
            'port': int(os.environ.get('SENTRY_REDIS_PORT', '6379')),
            'db': 0,
        }
    }
}

# Cache configuration
SENTRY_CACHE = 'sentry.cache.redis.RedisCache'
SENTRY_CACHE_OPTIONS = SENTRY_REDIS_OPTIONS

# Queue configuration
CELERY_ALWAYS_EAGER = False
BROKER_URL = 'redis://{}:{}/0'.format(
    os.environ.get('SENTRY_REDIS_HOST', 'sentry-redis'),
    os.environ.get('SENTRY_REDIS_PORT', '6379')
)

# Email configuration
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.environ.get('SENTRY_MAIL_HOST', 'localhost')
EMAIL_PORT = int(os.environ.get('SENTRY_MAIL_PORT', '25'))
EMAIL_HOST_USER = os.environ.get('SENTRY_MAIL_USERNAME', '')
EMAIL_HOST_PASSWORD = os.environ.get('SENTRY_MAIL_PASSWORD', '')
EMAIL_USE_TLS = os.environ.get('SENTRY_MAIL_USE_TLS', 'false').lower() == 'true'
SERVER_EMAIL = os.environ.get('SENTRY_SERVER_EMAIL', 'sentry@localhost')

# Security configuration
SECRET_KEY = os.environ.get('SENTRY_SECRET_KEY', 'your-secret-key-here')
ALLOWED_HOSTS = os.environ.get('SENTRY_ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

# URL configuration
SENTRY_URL_PREFIX = os.environ.get('SENTRY_URL_PREFIX', 'http://localhost/sentry')

# File storage
SENTRY_FILESTORE = 'django.core.files.storage.FileSystemStorage'
SENTRY_FILESTORE_OPTIONS = {
    'location': '/var/lib/sentry/files',
}

# Performance settings
SENTRY_OPTIONS = {
    'system.event-retention-days': 90,
    'system.rate-limit': 0,
    'system.datascrubbing.enabled': True,
    'system.datascrubbing.scrub-defaults': True,
    'system.datascrubbing.scrub-data': True,
    'system.datascrubbing.scrub-ip-addresses': True,
}

# Debug mode
DEBUG = os.environ.get('SENTRY_DEBUG', 'false').lower() == 'true'

# Logging configuration
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s'
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose'
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
} 