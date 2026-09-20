from django.utils.dateparse import parse_date
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Animal, RegistroCcs


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


def serializar_registro_ccs(r):
    return {
        'id': r.id,
        'valor_ccs': r.valor_ccs,
        'data_coleta': r.data_coleta.isoformat(),
        'laboratorio': r.laboratorio,
        'observacoes': r.observacoes,
        'risco': r.risco,
        'risco_display': RegistroCcs.Risco(r.risco).label,
        'criado_em': r.criado_em.isoformat(),
    }


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def registros_ccs(request, animal_id):
    try:
        animal = Animal.objects.get(id=animal_id, usuario=request.user)
    except Animal.DoesNotExist:
        return Response({'status': 'erro', 'mensagem': 'Animal não encontrado.'}, status=404)

    if request.method == 'GET':
        registros = animal.registros_ccs.all()
        return Response({'status': 'sucesso', 'registros_ccs': [serializar_registro_ccs(r) for r in registros]})

    valor_ccs_raw = request.data.get('valor_ccs')
    data_coleta_raw = request.data.get('data_coleta')

    if valor_ccs_raw in (None, '') or not data_coleta_raw:
        return Response({'status': 'erro', 'mensagem': 'Valor da CCS e data da coleta são obrigatórios.'}, status=400)

    try:
        valor_ccs = int(valor_ccs_raw)
        if valor_ccs < 0:
            raise ValueError
    except (TypeError, ValueError):
        return Response({'status': 'erro', 'mensagem': 'Valor da CCS inválido.'}, status=400)

    data_coleta = parse_date(data_coleta_raw)
    if not data_coleta:
        return Response({'status': 'erro', 'mensagem': 'Data da coleta inválida.'}, status=400)

    if data_coleta > timezone.localdate():
        return Response({'status': 'erro', 'mensagem': 'A data da coleta não pode ser no futuro.'}, status=400)

    registro = RegistroCcs.objects.create(
        animal=animal,
        valor_ccs=valor_ccs,
        data_coleta=data_coleta,
        laboratorio=(request.data.get('laboratorio') or '').strip(),
        observacoes=(request.data.get('observacoes') or '').strip(),
    )
    from alertas.services import verificar_alerta_ccs_elevado
    verificar_alerta_ccs_elevado(registro)

    return Response({'status': 'sucesso', 'registro_ccs': serializar_registro_ccs(registro)})


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def registro_ccs_detalhe(request, animal_id, registro_id):
    try:
        registro = RegistroCcs.objects.get(id=registro_id, animal_id=animal_id, animal__usuario=request.user)
    except RegistroCcs.DoesNotExist:
        return Response({'status': 'erro', 'mensagem': 'Registro não encontrado.'}, status=404)

    registro.delete()
    return Response({'status': 'sucesso'})