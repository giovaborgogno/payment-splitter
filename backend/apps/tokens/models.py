from django.db import models
from django_softdelete.models import SoftDeleteModel

from apps.base.models import NamedModel, TimeStampedModel
from apps.chain.models import Chain


class ERC20Token(SoftDeleteModel, TimeStampedModel, NamedModel):
    symbol = models.CharField(max_length=255)
    address = models.CharField(max_length=255)
    chain = models.ForeignKey(Chain, on_delete=models.CASCADE)
    
    class Meta:
        verbose_name = "ERC20 Token"
        verbose_name_plural = "ERC20 Tokens"
        
        constraints = [
            models.UniqueConstraint(
                fields=('address', 'chain_id'),
                condition=models.Q(deleted_at=None),
                name='unique_erc20token_address_chain_id'
            )
        ]
