from django.utils.dateparse import parse_date
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Animal


def calcular_carencia(a):
    tratamento_ativo = a.tratamentos.filter(data_fim_carencia__gte=timezone.localdate()).order_by('-data_fim_carencia').first()
    if tratamento_ativo:
        return True, tratamento_ativo.data_fim_carencia
    return False, None


def calcular_alerta_reincidencia(a):
    ultimas = a.analises.order_by('-criado_em')[:3]
    suspeitas = sum(1 for analise in ultimas if analise.resultado == 'Possível presença de mastite')
    return suspeitas >= 2


def obter_ultima_analise(a):
    ultima = a.analises.order_by('-criado_em').first()
    if not ultima:
        return None
    return {
        'resultado': ultima.resultado,
        'confianca': f"{ultima.confianca}%",
        'criado_em': ultima.criado_em.isoformat(),
    }


def serializar_animal(request, a):
    em_carencia, carencia_ate = calcular_carencia(a)
    return {
        'id': a.id,
        'brinco': a.brinco,
        'nome': a.nome,
        'raca': a.raca,
        'data_nascimento': a.data_nascimento.isoformat() if a.data_nascimento else None,
        'sexo': a.sexo,
        'peso': str(a.peso) if a.peso else None,
        'observacoes': a.observacoes,
        'foto': request.build_absolute_uri(a.foto.url) if a.foto else None,
        'total_analises': a.analises.count() if hasattr(a, 'analises') else 0,
        'em_carencia': em_carencia,
        'carencia_ate': carencia_ate.isoformat() if carencia_ate else None,
        'alerta_reincidencia': calcular_alerta_reincidencia(a),
        'ultima_analise': obter_ultima_analise(a),
    }


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def animais(request):
    if request.method == 'GET':
        lista = Animal.objects.filter(usuario=request.user)
        return Response({'status': 'sucesso', 'animais': [serializar_animal(request, a) for a in lista]})

    brinco = (request.data.get('brinco') or '').strip()
    if not brinco:
        return Response({'status': 'erro', 'mensagem': 'O brinco é obrigatório.'}, status=400)

    if Animal.objects.filter(usuario=request.user, brinco=brinco).exists():
        return Response({'status': 'erro', 'mensagem': 'Já existe um animal com esse brinco.'}, status=400)

    data_nascimento_raw = request.data.get('data_nascimento')
    peso_raw = request.data.get('peso')

    animal = Animal.objects.create(
        usuario=request.user,
        brinco=brinco,
        nome=(request.data.get('nome') or '').strip(),
        raca=(request.data.get('raca') or '').strip(),
        data_nascimento=parse_date(data_nascimento_raw) if data_nascimento_raw else None,
        sexo=request.data.get('sexo', 'Fêmea'),
        peso=peso_raw if peso_raw else None,
        observacoes=(request.data.get('observacoes') or '').strip(),
        foto=request.FILES.get('foto')
    )
    return Response({'status': 'sucesso', 'animal': serializar_animal(request, animal)})


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def animal_detalhes(request, animal_id):
    try:
        animal = Animal.objects.get(id=animal_id, usuario=request.user)
    except Animal.DoesNotExist:
        return Response({'status': 'erro', 'mensagem': 'Animal não encontrado.'}, status=404)

    if request.method == 'GET':
        return Response({'status': 'sucesso', 'animal': serializar_animal(request, animal)})

    if request.method == 'PUT':
        animal.brinco = (request.data.get('brinco') or animal.brinco).strip()
        animal.nome = (request.data.get('nome') or '').strip()
        animal.raca = (request.data.get('raca') or '').strip()

        data_nascimento_raw = request.data.get('data_nascimento')
        animal.data_nascimento = parse_date(data_nascimento_raw) if data_nascimento_raw else None

        animal.sexo = request.data.get('sexo', animal.sexo)
        peso_raw = request.data.get('peso')
        if peso_raw is not None:
            animal.peso = peso_raw if peso_raw != '' else None
        animal.observacoes = (request.data.get('observacoes') or '').strip()

        if 'foto' in request.FILES:
            animal.foto = request.FILES.get('foto')

        animal.save()
        return Response({'status': 'sucesso', 'animal': serializar_animal(request, animal)})

    animal.delete()
    return Response({'status': 'sucesso'})