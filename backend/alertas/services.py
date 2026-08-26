from datetime import timedelta
from django.utils import timezone
from .models import Alerta

DURACAO_CICLO_CIO_DIAS = 21  # média do ciclo estral em bovinos


def verificar_alerta_reincidencia(animal):
    """Cria (ou resolve) o alerta de reincidência com base nas 3 análises mais recentes."""
    ultimas = animal.analises.order_by('-criado_em')[:3]
    suspeitas = sum(1 for a in ultimas if a.resultado == 'Possível presença de mastite')

    if suspeitas >= 2:
        ja_existe = Alerta.objects.filter(animal=animal, tipo='REINCIDENCIA_MASTITE', ativo=True).exists()
        if not ja_existe:
            Alerta.objects.create(
                usuario=animal.usuario,
                animal=animal,
                tipo='REINCIDENCIA_MASTITE',
                mensagem=f"{animal.brinco} apresentou {suspeitas} resultado(s) suspeito(s) entre as últimas 3 análises.",
            )
    else:
        # A situação melhorou (ex: nova análise voltou ao normal) — resolve automaticamente.
        Alerta.objects.filter(animal=animal, tipo='REINCIDENCIA_MASTITE', ativo=True).update(
            ativo=False, resolvido_em=timezone.now()
        )


def verificar_alerta_carencia(tratamento):
    """Cria o alerta de carência assim que um tratamento é registrado."""
    animal = tratamento.animal
    if tratamento.data_fim_carencia < timezone.localdate():
        return  # tratamento já vencido no momento do cadastro, não precisa alertar

    ja_existe = Alerta.objects.filter(animal=animal, tipo='CARENCIA', ativo=True).exists()
    if not ja_existe:
        Alerta.objects.create(
            usuario=animal.usuario,
            animal=animal,
            tipo='CARENCIA',
            mensagem=f"{animal.brinco} está em carência até {tratamento.data_fim_carencia:%d/%m/%Y}. Não misture o leite ao tanque.",
            data_referencia=tratamento.data_fim_carencia,
        )


def resolver_alertas_carencia_vencidos(usuario):
    """Fecha automaticamente alertas de carência cuja data já passou."""
    Alerta.objects.filter(
        usuario=usuario, tipo='CARENCIA', ativo=True, data_referencia__lt=timezone.localdate()
    ).update(ativo=False, resolvido_em=timezone.now())


def verificar_alerta_cio(animal):
    """Cria o alerta de cio quando a data prevista (última + ~21 dias) está próxima."""
    if not animal.data_ultimo_cio:
        return

    proximo_cio = animal.data_ultimo_cio + timedelta(days=DURACAO_CICLO_CIO_DIAS)
    hoje = timezone.localdate()
    janela_inicio = proximo_cio - timedelta(days=1)
    janela_fim = proximo_cio + timedelta(days=2)

    if janela_inicio <= hoje <= janela_fim:
        ja_existe = Alerta.objects.filter(
            animal=animal, tipo='CIO', ativo=True, data_referencia=proximo_cio
        ).exists()
        if not ja_existe:
            Alerta.objects.create(
                usuario=animal.usuario,
                animal=animal,
                tipo='CIO',
                mensagem=f"{animal.brinco} deve entrar no período de cio por volta de {proximo_cio:%d/%m/%Y}.",
                data_referencia=proximo_cio,
            )
    else:
        # Fora da janela esperada — fecha alertas de cio antigos que já passaram.
        Alerta.objects.filter(
            animal=animal, tipo='CIO', ativo=True, data_referencia__lt=hoje - timedelta(days=2)
        ).update(ativo=False, resolvido_em=timezone.now())


def sincronizar_alertas_usuario(usuario):
    """Roda todas as verificações (reincidência, carência, cio) para todos os
    animais do usuário. Chamado sempre que a lista de alertas é consultada,
    já que o projeto não usa tarefas agendadas em segundo plano."""
    from rebanho.models import Animal

    resolver_alertas_carencia_vencidos(usuario)
    for animal in Animal.objects.filter(usuario=usuario):
        verificar_alerta_reincidencia(animal)
        verificar_alerta_cio(animal)