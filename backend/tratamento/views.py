from django.utils.dateparse import parse_date
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Tratamento
from rebanho.models import Animal

# Create your views here.
def serializar_tratamento(t):
    return {
        'id': t.id,
        'medicamento': t.medicamento,
        'data_inicio': t.data_inicio.isoformat(),
        'data_fim_carencia': t.data_fim_carencia.isoformat(),
        'observacoes': t.observacoes,
    }

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def tratamentos(request, animal_id):
    try:
        animal=Animal.objects.get(id=animal_id, usuario=request.user)
    except Animal.DoesNotExist:
        return Response({'status': 'erro', 'mensagem': 'Animal não encontrado.'},status=404)

    if request_method == 'GET':
        lista = animal.tratamentos.all()
        return Response({'status': 'sucesso', 'tratamentos': [serializar_tratamento(t) for t in lista]})

    # POST - resgistrar novo tratamento
    data_inicio_raw = request.data.get('data_inicio')
    data_fim_raw = request.data.get('data_fim_carencia')

    if not data_fim_raw or not data_fim_raw:
        return Response({'status': 'erro', 'mensagem': 'Informe a data de início e a data de fim da carência.'})

    tratamento = Tratamento.objects.create(
        animal = animal,
        medicamento = (request.data.get('medicamento') or '').strip(),
        data_inicio = parse_date(data_inicio_raw),
        data_fim_carencia = parse_date(data_fim_raw),
        observacoes = (request.data.get('observacoes') or '').strip(), 
    )
    return Response({'status': 'sucesso', 'tratamento': serializar_tratamento(tratamento)})