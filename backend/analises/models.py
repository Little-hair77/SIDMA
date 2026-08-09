from django.db import models
from django.conf import settings

class Analise(models.Model):
    class Resultado(models.TextChoices):
        SEM_INDICIOS = 'Sem indícios de mastite', 'Sem indícios de mastite'
        POSSIVEL_MASTITE = 'Possível presença de mastite', 'Possível presença de mastite'
        AVALIACAO_ADCIONAL = 'Necessária avaliação adicional', 'Necessária avaliação adicional'

        usuario = models.ForeignKey(
            settings.AUTH_USER_MODEL,
            on_delete=models.CASCADE,
            related_name='analises',
        )
        imagem = models.ForeignKey(upload_to='amostras/%Y/%d')
        resultado = models.CharField(max_length=64, choices=Resultaddo.choices)
        confianca = models.FloatField(help_text="Percentual de confiança da IA (1 a 100)")
        criado_em = models.DateTimeField(auto_now_add=True)
        observacoes = models.TextField(blank=True, null=True)

        class Meta:
            ordering = ['-criado_em']
            verbose_name = 'Análise'
            verbose_name_plutal = "Análises"

        def __str__(self):
            return f"{self.resultado} ({self.confianca}%) - {self.criado_em:%d/%m/%Y %H:%M}"