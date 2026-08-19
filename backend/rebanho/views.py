from django.utils.dateparse import parse_date
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Animal

def serializar_animal(request, a):
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
    }

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def animais(request):
    if request.method == 'GET':
        lista = Animal.objects.filter(usuario=request.user)
        return Response({'status': 'sucesso', 'animais': [serializar_animal(request, a) for a in lista]})

    # POST - criar novo animal
    brinco = (request.data.get('brinco') or '').strip()
    if not brinco:
        return Response({'status': 'erro', 'mensagem': 'O brinco é obrigatório.'}, status=400)

    if Animal.objects.filter(usuario=request.user, brinco=brinco).exists():
        return Response({'status': 'erro', 'mensagem': 'Já existe um animal com esse brinco.'})

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
        foto=request.FILES.get('foto') # Captura o arquivo de imagem
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

        # Atualiza a foto apenas se uma nova for enviada
        if 'foto' in request.FILES:
            animal.foto = request.FILES.get('foto')

        animal.save()
        return Response({'status': 'sucesso', 'animal': serializar_animal(request, animal)})

    # DELETE
    animal.delete()
    return Response({'status': 'sucesso'})