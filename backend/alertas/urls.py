from django.urls import path
from . import views

urlpatterns = [
    path('alertas/', views.listar_alertas, name='listar_alertas'),
    path('alertas/<int:alerta_id>/resolver/', views.resolver_alerta, name='resolver_alerta'),
]