from django.contrib import admin
from .models import Analise

# Register your models here.
class AnaliseAdmin(admin.ModelAdmin):
    list_display = ('id', 'usuario', 'animal', 'resultado', 'confianca', 'criado_em')
    list_filter = ('resultado', 'criado_em')
    readonly_fields = ('criado_em')