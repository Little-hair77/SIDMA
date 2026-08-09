from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import random

@csrf_exempt
def diagnosticar_leite(request):
    if request.method == 'POST' and request.FILES.get('imagem'):
        # Recebe o arquivo enviado pelo Flutter
        imagem_recebida = request.FILES['imagem']

        # Simulação mock (enquanto o modelo não está pronto)
        resultado_ia = random.choice(['Sem indícios de mastite', 'Possível presença de mastite', 'Necessária avaliação adicional'])
        confianca = round(random.uniform(70.0, 99.0), 2)

        # Posteriormente, esse bloco salvará a referência da imagem e o resultado no PostgreSQL
        return JsonResponse({
            'status': 'sucesso',
            'resultado': resultado_ia,
            'confianca': f"{confianca}%",
            'mensagem': 'Análise processada com sucesso (Simulação).'
        })
    return JsonResponse({'status': 'erro', 'mensagem': 'Requisição Inválida.'}, status=400)
    