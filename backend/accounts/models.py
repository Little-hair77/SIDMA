import random

from django.conf import settings
from django.db import models
from django.utils import timezone


def gerar_codigo():
    return f"{random.randint(0, 999999):06d}"


class CodigoRecuperacaoSenha(models.Model):
    # Código de verificação de 6 dígitos para o fluxo 'Esqueci minha senha'

    VALIDADE_MINUTOS = 15

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='codigos_recuperacao')
    codigo = models.CharField(max_length=6, default=gerar_codigo)
    criado_em = models.DateTimeField(auto_now_add=True)
    usado = models.BooleanField(default=False)

    class Meta:
        verbose_name = 'Código de Recuperação de Senha'
        verbose_name_plural = 'Códigos de Recuperação de Senha'
        ordering = ['-criado_em']

    def expirado(self):
        limite = self.criado_em + timezone.timedelta(minutes=self.VALIDADE_MINUTOS)
        return timezone.now() > limite

    def __str__(self):
        return f"{self.usuario.email} — {self.codigo} ({'usado' if self.usado else 'ativo'})"