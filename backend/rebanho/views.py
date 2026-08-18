from django.utils.dateparse import parse_date

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Animal

# Create your views here.
def serializar_animal(a):
    return {
        'id': a.id,
        'brinco': a.brinco,
        'nome': a.nome,
        'raca': a.raca,
        'data_nascimento': a.data_nascimento.isoformat() if a.data_nascimento else None,
        'total_analises': a.analises.count(),
    }

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def animais(request):
    if request.method == 'GET':
        lista = Animal.objects.filter(usuario=request.user)
        return Response({'status': 'sucesso', 'animais': [serializar_animal(a) for a in lista]})

    # POST - criar novo animal
    brinco = (request.data.get('brinco') or '').strip()
    if not brinco:
        return Response({'status': 'erro', 'mensagem': 'O brinco é obrigatório.'}, status=400)

    if Animal.objects.filter(usuario=request.user, brinco=brinco).exists():
        return Response({'status': 'erro', 'mensagem': 'Já existe um animal com esse brinco.'})

    data_nascimento_raw = request.data.get('data_nascimento')
    animal = Animal.objects.create(
        usuario = request.user,
        brinco = brinco,
        nome = (request.data.get('nome') or '').strip(),
        raca = (request.data.get('raca') or '').strip(),
        data_nascimento = parse_date(data_nascimento_raw) if data_nascimento_raw else None,
    )
    return Response({'status': 'sucesso', 'animal': serializar_animal(animal)})

@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def animal_detalhes(request, animal_id):
    try:
        animal = Animal.objects.get(id=animal_id, usuario=request.user)
    except Animal.DoesNotExist:
        return Response({'status': 'erro', 'mensagem': 'Animal não encontrado.'}, status=404)

    if request.method == 'GET':
        return Response({'status': 'sucesso', 'animal': serializar_animal(animal)})

    if request.method == 'PUT':
        animal.brinco = (request.data.get('brinco') or animal.brinco).strip()
        animal.nome = (request.data.get('nome') or '').strip()
        animal.raca = (request.data.get('raca') or '').strip()
        data_nascimento_raw = request.data.get('data_nascimento')
        animal.data_nascimento = parse_date(data_nascimento_raw) if data_nascimento_raw else None
        animal.save()
        return Response({'status': 'sucesso', 'animal': serializar_animal(animal)})

    # DELETE
    animal.delete()
    return Response({'status': 'sucesso'})