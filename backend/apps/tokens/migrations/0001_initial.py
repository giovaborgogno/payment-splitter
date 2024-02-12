# Generated by Django 5.0.2 on 2024-02-12 21:04

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('chain', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='ERC20Token',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('deleted_at', models.DateTimeField(blank=True, null=True)),
                ('restored_at', models.DateTimeField(blank=True, null=True)),
                ('name', models.CharField(max_length=255)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('symbol', models.CharField(max_length=255)),
                ('address', models.CharField(max_length=255)),
                ('chain', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='chain.chain')),
            ],
            options={
                'verbose_name': 'ERC20 Token',
                'verbose_name_plural': 'ERC20 Tokens',
            },
        ),
        migrations.AddConstraint(
            model_name='erc20token',
            constraint=models.UniqueConstraint(condition=models.Q(('deleted_at', None)), fields=('address', 'chain_id'), name='unique_erc20token_address_chain_id'),
        ),
    ]