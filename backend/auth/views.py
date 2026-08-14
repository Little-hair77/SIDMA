from django.conf import settings
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
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

@api_view(['POST'])
@permission_classes([AllowAny])
def registrar_usuario(request):
    nome = (request.data.get('nome') or '').strip()
    email = (request.data.get('email') or '').strip().lower()
    senha = request.data.get('senha') or ''

    if not email or not senha:
        return Response({'status': 'erro', 'mensagem': 'E-mail e senha são obrigatórios.'}, status=400)

    if User.objects.filter(username=email).exists():
        return Response({'status': 'erro', 'mensagem': 'Já existe uma conta com esse e-mail.'}, status=400)

    try:
        validate_password(senha)
    except DjangoValidationError as e:
        return Response({'status': 'erro', 'mensagem': ' '.join(e.messages)}, status=400)

    usuario = User.objects.create_user(username=email, email=email, password=senha, first_name=nome)
    return Response(resposta_com_token(usuario))

@api_view(['POST'])
@permission_classes([AllowAny])
def login_usuario(request):
    email = (request.data.get('email') or '').strip().lower()
    senha = request.data.get('senha') or ''

    usuario = aauthenticate(username=email, password=senha)
    if usuario is None:
        return Response({'status': 'erro', 'mensagem': 'E-mail ou Senha inválidos.'}, status=401)

    return Response(resposta_com_token(usuario))

@api_view(['POST'])
@permission_classes([AllowAny])
def google_login(request):
    """Recebe o ID token o Google (enviado pelo flutter), valida,
    cria/recupera o usuário e devolve tokens JWT do sistema."""
    token = request.data.get('id_token')
    if not token:
        return Response({'status': 'erro', 'mensagem': 'id_token não informado.'}, status=400)

    try:
        info = id_token.verify_oauth2_token(token, google_requests.Request(), settings.GOOGLE_CLIENT_ID)
    except ValueError:
        return Response({'status': 'erro', 'mensagem': 'Token do Google inválido.'}, status=401)

    email = info.get('email')
    nome = info.get('name', '')

    if not email:
        return Response({'status': 'erro', 'mensagem': 'Não foi possível obter o e-mail da conta Google.'}, status=400)

    usuario, _ = User.objects.get_or_create(
        username=email,
        defaults={'email': email, 'first_name': nome},
    )

    return Response(resposta_com_token(usuario))