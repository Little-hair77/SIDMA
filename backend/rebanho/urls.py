from django.urls import path
from . import views

urlpatterns = [
    path('animais/', views.animais, name='animais'),
    path('animais/<int:animal_id>/', views.animal_detalhes, name='animal_detalhes'),
    path('animais/<int:animal_id>/ccs/', views.registros_ccs, name='registros_ccs'),
    path('animais/<int:animal_id>/ccs/<int:registro_id>/', views.registro_ccs_detalhe, name='registro_ccs_detalhe'),
]