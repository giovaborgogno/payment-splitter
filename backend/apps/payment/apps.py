# apps/test_api/__init__.py
from django.apps import AppConfig


class PaymentConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.payment'
