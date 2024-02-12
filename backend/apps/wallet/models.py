from django.db import models
from django_softdelete.managers import SoftDeleteManager
from django_softdelete.models import SoftDeleteModel
from siwe_auth.models import AbstractWallet, WalletManager as BaseWalletManager

from apps.base.models import TimeStampedModel


class WalletManager(SoftDeleteManager, BaseWalletManager):
    pass


class Wallet(SoftDeleteModel, AbstractWallet, TimeStampedModel):
    objects = WalletManager()
    
    
class WalletRelatedModel(models.Model):
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE)
    
    class Meta:
        abstract = True
