from django.contrib import admin
from .models import Alerta

# Register your models here.
@admin.register(Alerta)
class AlertaAdmin(admin.ModelAdmin):
    list_display = ('id', 'animal', 'tipo', 'ativo', 'criado_em', 'resolvido_em')
    list_filter = ('tipo', 'ativo')