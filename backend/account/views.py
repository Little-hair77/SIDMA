from django.conf import settings
from google.oauth2 import id_token
from google.auth.transport import request as google_requests
from django.contrib.auth.models import User
from django.contrib.auth import aauthenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

# Create your views here.
def resposta_com_token(usuario):
    """Monta a resposta padrão com tokens JWT + dados do usuário,
    reaproveitada pelo login Google, cadastro e login tradicional"""
    refresh = RefreshToken.for_user(usuario)
    return{
        'status' : 'sucesso',
        'access' : str(refresh.access_token),
        'refresh' : str(refresh),
        'usuario' : {'email': usuario.email, 'nome': usuario.first_name},
    }