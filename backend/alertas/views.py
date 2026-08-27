from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Alerta
from .services import sincronizar_alertas_usuario

# Create your views here.
def serializar_alerta(a):
    return {
        'id': a.id,
        'tipo': a.tipo,
        'tipo_display': a.get_tipo_display(),
        'mensagem': a.mensagem,
        'animal': {'id': a.animal.id, 'brinco': a.animal.brinco, 'nome': a.animal.nome},
        'data_referencia': a.data_referencia.isoformat() if a.data_referencia else None,
        'criado_em': a.criado_em.isoformat(),
    }

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def listar_alertas(request):
    # Roda as verificações antes de listar, já que não há tarefa agendada em segundo plano
    sincronizar_alertas_usuario(request.user)

    alertas = Alerta.objects.filter(usuario=request.user, ativo=True).select_related('animal')
    return Response({'status': 'sucesso', 'alertas': [serializar_alerta(a) for a in alertas]})

