from django.conf import settings
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.mail import send_mail

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .models import CodigoRecuperacaoSenha

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

    usuario = authenticate(username=email, password=senha)
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


@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def perfil_usuario(request):
    """Consulta e atualização dos dados de perfil (nome e e-mail) do usuário autenticado."""
    usuario = request.user

    if request.method == 'GET':
        return Response({'status': 'sucesso', 'nome': usuario.first_name, 'email': usuario.email})

    nome = (request.data.get('nome') or '').strip()
    email = (request.data.get('email') or '').strip().lower()

    if not nome or not email:
        return Response({'status': 'erro', 'mensagem': 'Nome e e-mail são obrigatórios.'}, status=400)

    if User.objects.filter(email=email).exclude(id=usuario.id).exists():
        return Response({'status': 'erro', 'mensagem': 'Já existe uma conta com esse e-mail.'}, status=400)

    usuario.first_name = nome
    usuario.email = email
    usuario.username = email  # login é feito por e-mail, então username precisa acompanhar
    usuario.save()

    return Response({'status': 'sucesso', 'nome': usuario.first_name, 'email': usuario.email})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def alterar_senha(request):
    """Troca de senha para o usuário já logado no app (tela Perfil > Segurança
    e Senha). Diferente do fluxo de recuperação por e-mail (RF07): aqui é
    preciso confirmar a senha atual, já que o usuário já está autenticado."""
    usuario = request.user
    senha_atual = request.data.get('senha_atual') or ''
    nova_senha = request.data.get('nova_senha') or ''

    if not senha_atual or not nova_senha:
        return Response({'status': 'erro', 'mensagem': 'Informe a senha atual e a nova senha.'}, status=400)

    if not usuario.check_password(senha_atual):
        return Response({'status': 'erro', 'mensagem': 'Senha atual incorreta.'}, status=400)

    try:
        validate_password(nova_senha, user=usuario)
    except DjangoValidationError as e:
        return Response({'status': 'erro', 'mensagem': ' '.join(e.messages)}, status=400)

    if usuario.check_password(nova_senha):
        return Response({'status': 'erro', 'mensagem': 'A nova senha deve ser diferente da atual.'}, status=400)

    usuario.set_password(nova_senha)
    usuario.save()

    return Response({'status': 'sucesso', 'mensagem': 'Senha alterada com sucesso.'})


@api_view(['POST'])
@permission_classes([AllowAny])
def solicitar_recuperacao_senha(request):
    """Etapa 1 do RF07: gera e 'envia' (via e-mail, ver EMAIL_BACKEND) um
    código de 6 dígitos para o e-mail informado."""
    email = (request.data.get('email') or '').strip().lower()
    if not email:
        return Response({'status': 'erro', 'mensagem': 'Informe o e-mail cadastrado.'}, status=400)

    # A mensagem de resposta é sempre a mesma, exista ou não conta com esse
    # e-mail, para não revelar quais e-mails têm cadastro no sistema.
    mensagem_padrao = 'Se este e-mail estiver cadastrado, um código de verificação foi enviado.'

    usuario = User.objects.filter(email=email).first()
    if usuario is not None:
        codigo_obj = CodigoRecuperacaoSenha.objects.create(usuario=usuario)
        send_mail(
            subject='SIDMA — Código de recuperação de senha',
            message=(
                f'Olá, {usuario.first_name or usuario.email}.\n\n'
                f'Seu código de verificação é: {codigo_obj.codigo}\n'
                f'Ele expira em {CodigoRecuperacaoSenha.VALIDADE_MINUTOS} minutos.\n\n'
                'Se você não solicitou essa recuperação, ignore este e-mail.'
            ),
            from_email=None,  # usa settings.DEFAULT_FROM_EMAIL
            recipient_list=[usuario.email],
            fail_silently=True,
        )

    return Response({'status': 'sucesso', 'mensagem': mensagem_padrao})


@api_view(['POST'])
@permission_classes([AllowAny])
def confirmar_recuperacao_senha(request):
    """Etapa 2 do RF07: valida o código de 6 dígitos e define a nova senha."""
    email = (request.data.get('email') or '').strip().lower()
    codigo = (request.data.get('codigo') or '').strip()
    nova_senha = request.data.get('nova_senha') or ''

    if not email or not codigo or not nova_senha:
        return Response({'status': 'erro', 'mensagem': 'Preencha e-mail, código e nova senha.'}, status=400)

    usuario = User.objects.filter(email=email).first()
    codigo_obj = (
        CodigoRecuperacaoSenha.objects
        .filter(usuario=usuario, codigo=codigo, usado=False)
        .order_by('-criado_em')
        .first()
        if usuario is not None else None
    )

    if codigo_obj is None or codigo_obj.expirado():
        return Response({'status': 'erro', 'mensagem': 'Código inválido ou expirado.'}, status=400)

    try:
        validate_password(nova_senha, user=usuario)
    except DjangoValidationError as e:
        return Response({'status': 'erro', 'mensagem': ' '.join(e.messages)}, status=400)

    usuario.set_password(nova_senha)
    usuario.save()

    codigo_obj.usado = True
    codigo_obj.save(update_fields=['usado'])

    return Response({'status': 'sucesso', 'mensagem': 'Senha redefinida com sucesso. Faça login com a nova senha.'})