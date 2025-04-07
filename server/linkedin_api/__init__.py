# Import celery app
from .celery import app as celery_app

# Make celery available at module level
__all__ = ('celery_app',)