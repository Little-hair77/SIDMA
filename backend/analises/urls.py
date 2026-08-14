from django.urls import path
from . import views

urlpatterns = [
    path('diagnosticar/', views.diagnosticar_leite, name='diagnosticar_leite'),
    path('historico/', views.listar_historico, name='listar_historico'),
    path('analises/<int:analise_id>/', views.analise_detalhe, name='analise_detalhe'),
]