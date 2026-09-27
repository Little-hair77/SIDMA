from django.urls import path
from . import views

urlpatterns = [
    path('auth/google/', views.google_login, name='google_login'),
    path('auth/registrar/', views.registrar_usuario, name='registrar_usuario'),
    path('auth/login/', views.login_usuario, name='login_usuario'),
    path('auth/recuperar-senha/solicitar/', views.solicitar_recuperacao_senha, name='solicitar_recuperacao_senha'),
    path('auth/recuperar-senha/confirmar/', views.confirmar_recuperacao_senha, name='confirmar_recuperacao_senha'),
    path('perfil/', views.perfil_usuario, name='perfil_usuario'),
    path('perfil/alterar-senha/', views.alterar_senha, name='alterar_senha'),
]