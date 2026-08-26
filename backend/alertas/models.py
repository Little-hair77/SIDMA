from django.db import models
from rebanho.models import Animal

# Create your models here.
class Alerta(models.Model):
    TIPO_CHOICES = [
        ('REINCIDENCIA_MASTITE', 'Reincidência da Mastite'),
        ('CARENCIA', 'Fim de Carência'),
        ('CIO', 'Período de Cio (Atenção Reprodutiva)'),
        ('OUTRO', 'Outro Alerta'),
    ]

    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='alertas')
    tipo = models.CharField(max_length=50, choices=TIPO_CHOICES)
    mensagem = models.TextField()
    ativo = models.BooleanField(default=True)
    criado_em = models.DateTimeField(auto_now_add=True)
    resolvido_em = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.animal.nome} - {self.get_tipo_display()}"

    class Meta:
        verbose_name = 'Alerta'
        verbose_name_plural = "Alertas"
        ordering = ['-criado_em']