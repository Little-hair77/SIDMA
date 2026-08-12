from django.urls import path
from . import views

urlpatterns = [
    path('auth/google/', views.google_login, name='google_logiin'),
    path('auth/registrar/', views.registrar_usuario, name='registrar_usuario'),
    path('auth/login/', views.login_usuario, name='login_usuario'),
    path('diagnosticar/', views.diagnosticar_leite, name='diagnosticar_leite'),
    path('historico/', views.listar_historico, name='listar_historico'),
]