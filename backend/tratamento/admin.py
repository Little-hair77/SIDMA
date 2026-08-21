from django.contrib import admin
from .models import Tratamento


@admin.register(Tratamento)
class TratamentoAdmin(admin.ModelAdmin):
    list_display = ('id', 'animal', 'medicamento', 'data_inicio', 'data_fim_carencia')
    list_filter = ('data_fim_carencia',)