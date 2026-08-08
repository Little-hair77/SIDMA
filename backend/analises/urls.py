from django.urls import path
from . import views

urlpatterns = [
    path('diagnosticar/', views.diagnosticar_leite, name='diagnosticar_leite'),
]