import random

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Analise
from rebanho.models import Animal


def serializar_analise(a, request):
    return {
        'id': a.id,
        'resultado': a.resultado,
        'confianca': f"{a.confianca}%",
        'imagem_url': request.build_absolute_uri(a.imagem.url),
        'criado_em': a.criado_em.isoformat(),
        'observacoes': a.observacoes or '',
        'animal': {
            'id': a.animal.id,
            'brinco': a.animal.brinco,
            'nome': a.animal.nome,
        } if a.animal else None,
    }


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def diagnosticar_leite(request):
    if not request.FILES.get('imagem'):
        return Response({'status': 'erro', 'mensagem': 'Requisição Inválida.'}, status=400)

    imagem_recebida = request.FILES['imagem']

    animal = None
    animal_id = request.data.get('animal_id')
    if animal_id:
        animal = Animal.objects.filter(id=animal_id, usuario=request.user).first()

    # Simulação mock (enquanto o modelo de IA não está pronto)
    resultado_ia = random.choice([
        Analise.Resultado.SEM_INDICIOS,
        Analise.Resultado.POSSIVEL_MASTITE,
        Analise.Resultado.AVALIACAO_ADICIONAL,
    ])
    confianca = round(random.uniform(70.0, 99.0), 2)

    analise = Analise.objects.create(
        usuario=request.user,
        animal=animal,
        imagem=imagem_recebida,
        resultado=resultado_ia,
        confianca=confianca,
    )

    resposta = serializar_analise(analise, request)
    resposta['status'] = 'sucesso'
    resposta['mensagem'] = 'Análise processada com sucesso (Simulação).'
    return Response(resposta)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def listar_historico(request):
    analises = Analise.objects.filter(usuario=request.user)

    resultado_filtro = request.query_params.get('resultado')
    if resultado_filtro:
        analises = analises.filter(resultado=resultado_filtro)

    from django.utils.dateparse import parse_date

    data_inicio = request.query_params.get('data_inicio')
    if data_inicio:
        analises = analises.filter(criado_em__date__gte=parse_date(data_inicio))

    data_fim = request.query_params.get('data_fim')
    if data_fim:
        analises = analises.filter(criado_em__date__lte=parse_date(data_fim))

    animal_id = request.query_params.get('animal_id')
    if animal_id:
        analises = analises.filter(animal_id=animal_id)

    analises = analises[:200]
    dados = [serializar_analise(a, request) for a in analises]
    return Response({'status': 'sucesso', 'analises': dados})


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def analise_detalhe(request, analise_id):
    try:
        analise = Analise.objects.get(id=analise_id, usuario=request.user)
    except Analise.DoesNotExist:
        return Response({'status': 'erro', 'mensagem': 'Análise não encontrada.'}, status=404)

    if request.method == 'PATCH':
        if 'observacoes' in request.data:
            analise.observacoes = request.data.get('observacoes')
        if 'animal_id' in request.data:
            novo_animal_id = request.data.get('animal_id')
            analise.animal = Animal.objects.filter(id=novo_animal_id, usuario=request.user).first() if novo_animal_id else None
        analise.save()

    return Response({'status': 'sucesso', 'analise': serializar_analise(analise, request)})