from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from . import views

urlpatterns = [
    path('animais/', views.animais, name='animais'),
    path('animais/<int:animal_id>/', views.animal_detalhes, name='animal_detalhes'),
]

# Permite que o Django sirva os arquivos de imagem em ambiente de desenvolvimento
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)