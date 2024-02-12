from django.contrib import admin

from django.contrib.auth import get_user_model
from siwe_auth.admin import WalletBaseAdmin

WalletModel = get_user_model()


# You can inherit from siwe_auth.admin.WalletBaseAdmin or from django.contrib.auth.admin.BaseUserAdmin if you preffer.
class WalletAdmin(WalletBaseAdmin): 
    fieldsets = (
        ("Wallet Info", {"fields": ("ethereum_address", "ens_name", "ens_avatar",)}),
        ("Permissions", {"fields": ("is_admin", "is_active",)}),
        ("More Info", {"fields": ("last_login", "created")})
    )
    readonly_fields = ["created", "ethereum_address", "last_login"]
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("ethereum_address",),
            },
        ),
    )
    
admin.site.register(WalletModel, WalletAdmin)