from django.urls import path
from . import views

urlpatterns = [
    path('auth/google/', views.google_login, name='google_login'),
    path('auth/registrar/', views.registrar_usuario, name='registrar_usuario'),
    path('auth/login/', views.login_usuario, name='login_usuario'),
]