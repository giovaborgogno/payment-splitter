from django.contrib import admin

from apps.payment.models import Payee, Payment, PaymentGroup

admin.site.register(Payee)  
admin.site.register(Payment)  
admin.site.register(PaymentGroup)  