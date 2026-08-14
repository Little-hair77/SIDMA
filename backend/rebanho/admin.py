from django.contrib import admin
from .models import Animal

# Register your models here.
@admin.register(Animal)
class AnimalAdmin(admin.ModelAdmin):
    list_display = ('id', 'brinco', 'usuario', 'criado_em')
    search_fields = ('brinco', 'nome')