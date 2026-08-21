from django.urls import path
from . import views

urlpatterns = [
    path('animais/<int:animal_id>/tratamentos/', views.tratamentos, name='tratamentos'),
]