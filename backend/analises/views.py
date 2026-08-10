import random

from django.conf import settings
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from django.contrib.auth.models import User

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Analise


@api_view(['POST'])
@permission_classes([AllowAny])
def google_login(request):
    """Recebe o ID token do Google (enviado pelo Flutter), valida,
    cria/recupera o usuário e devolve tokens JWT do nosso sistema."""
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

    refresh = RefreshToken.for_user(usuario)

    return Response({
        'status': 'sucesso',
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'usuario': {'email': usuario.email, 'nome': usuario.first_name},
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def diagnosticar_leite(request):
    if not request.FILES.get('imagem'):
        return Response({'status': 'erro', 'mensagem': 'Requisição Inválida.'}, status=400)

    imagem_recebida = request.FILES['imagem']

    # Simulação mock (enquanto o modelo de IA não está pronto)
    resultado_ia = random.choice([
        Analise.Resultado.SEM_INDICIOS,
        Analise.Resultado.POSSIVEL_MASTITE,
        Analise.Resultado.AVALIACAO_ADICIONAL,
    ])
    confianca = round(random.uniform(70.0, 99.0), 2)

    analise = Analise.objects.create(
        usuario=request.user,
        imagem=imagem_recebida,
        resultado=resultado_ia,
        confianca=confianca,
    )

    return Response({
        'status': 'sucesso',
        'id': analise.id,
        'resultado': analise.resultado,
        'confianca': f"{analise.confianca}%",
        'imagem_url': request.build_absolute_uri(analise.imagem.url),
        'criado_em': analise.criado_em.isoformat(),
        'mensagem': 'Análise processada com sucesso (Simulação).'
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def listar_historico(request):
    analises = Analise.objects.filter(usuario=request.user)[:100]
    dados = [
        {
            'id': a.id,
            'resultado': a.resultado,
            'confianca': f"{a.confianca}%",
            'imagem_url': request.build_absolute_uri(a.imagem.url),
            'criado_em': a.criado_em.isoformat(),
        }
        for a in analises
    ]
    return Response({'status': 'sucesso', 'analises': dados})