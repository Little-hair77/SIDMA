from django.db import models
from django.conf import settings
from rebanho.models import Animal


class Alerta(models.Model):
    TIPO_CHOICES = [
        ('REINCIDENCIA_MASTITE', 'Reincidência da Mastite'),
        ('CARENCIA', 'Fim de Carência'),
        ('CIO', 'Período de Cio (Atenção Reprodutiva)'),
        ('OUTRO', 'Outro Alerta'),
    ]

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='alertas')
    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='alertas')
    tipo = models.CharField(max_length=50, choices=TIPO_CHOICES)
    mensagem = models.TextField()
    data_referencia = models.DateField(
        null=True, blank=True,
        help_text="Data relevante para o alerta (ex: fim da carência, data prevista do cio)"
    )
    ativo = models.BooleanField(default=True)
    criado_em = models.DateTimeField(auto_now_add=True)
    resolvido_em = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.animal.brinco} - {self.get_tipo_display()}"

    class Meta:
        verbose_name = 'Alerta'
        verbose_name_plural = "Alertas"
        ordering = ['-criado_em']
        constraints = [
            # Garante, no nível do banco, que não existam dois alertas ATIVOS
            # do mesmo tipo para o mesmo animal ao mesmo tempo.
            models.UniqueConstraint(
                fields=['animal', 'tipo'],
                condition=models.Q(ativo=True),
                name='unico_alerta_ativo_por_tipo_animal',
            )
        ]