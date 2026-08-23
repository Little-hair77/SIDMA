from django.urls import path
from . import views

urlpatterns = [
    path('animais/', views.animais, name='animais'),
    path('animais/<int:animal_id>/', views.animal_detalhes, name='animal_detalhes'),
]