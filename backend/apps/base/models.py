from django.db import models


class NamedModel(models.Model):
    name = models.CharField(max_length=255)
    
    class Meta:
        abstract = True
        
    def __str__(self):
        return self.name
        
        
class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        abstract = True
        