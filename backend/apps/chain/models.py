from django.db import models

from apps.base.models import NamedModel


class Chain(NamedModel):
    chain_id = models.PositiveIntegerField(unique=True)
    native_currency = models.CharField(max_length=255)
