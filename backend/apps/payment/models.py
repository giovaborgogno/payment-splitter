from django.db import models
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django_softdelete.models import SoftDeleteModel
from siwe_auth.models import validate_ethereum_address

from apps.chain.models import Chain
from apps.base.models import NamedModel, TimeStampedModel
from apps.tokens.models import ERC20Token
from apps.wallet.models import WalletRelatedModel

Wallet = get_user_model()
    

class PaymentGroup(SoftDeleteModel, TimeStampedModel, WalletRelatedModel, NamedModel):
    detail = models.CharField(max_length=255, blank=True, null=True)
    chain = models.ForeignKey(Chain, on_delete=models.CASCADE, blank=True, null=True)
    token = models.ForeignKey(ERC20Token, on_delete=models.CASCADE, blank=True, null=True)
    
    @property
    def use_erc20(self):        
        return bool(self.token)
    
    @property
    def use_native_currency(self):        
        return not bool(self.token)
    
    def clean(self):
        super().clean()
        if self.token and self.chain != self.token.chain:
            raise ValidationError("If a token is specified, it must belong to the same chain.")
    

class Payee(SoftDeleteModel, NamedModel):
    wallet = models.CharField(max_length=255, validators=[validate_ethereum_address])
    payment_group = models.ForeignKey(PaymentGroup, on_delete=models.CASCADE)
    amount = models.PositiveIntegerField()
    
    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['wallet', 'payment_group'],
                condition=models.Q(deleted_at=None),
                name='payee_wallet_payment_group'
            )
        ]
    

class Payment(SoftDeleteModel, TimeStampedModel):
    payee = models.ForeignKey(Payee, on_delete=models.CASCADE)
    