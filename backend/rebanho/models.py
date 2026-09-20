from django.db import models
from django.conf import settings

class Animal(models.Model):
    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='animais',
    )
    brinco = models.CharField(max_length=30, help_text="Número de identificação/brinco do animal")
    nome = models.CharField(max_length=100, blank=True)
    raca = models.CharField(max_length=100, blank=True)
    data_nascimento = models.DateField(blank=True, null=True)
    data_ultimo_cio = models.DateField(
        blank=True, null=True,
        help_text="Data do último cio observado, usada para prever a próximo (~21 dias depois)"
    )
    sexo = models.CharField(
        max_length=10, 
        choices=[('Fêmea', 'Fêmea'), ('Macho', 'Macho')], 
        default='Fêmea'
    )
    peso = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    observacoes = models.TextField(null=True, blank=True)
    foto = models.ImageField(upload_to='fotos_animais/', null=True, blank=True)

    criado_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['brinco']
        verbose_name = 'Animal'
        verbose_name_plural = "Animais"
        constraints = [
            models.UniqueConstraint(fields=['usuario', 'brinco'], name='brinco_unico_por_usuario')
        ]

    def __str__(self):
        return f"{self.brinco} - {self.nome}" if self.nome else self.brinco


class RegistroCcs(models.Model):
    """Registro de Contagem de Células Somáticas (CCS) de um animal,
    normalmente resultado de um exame laboratorial, usado para triagem
    de mastite subclínica (que não é detectável pela análise de imagem)."""

    class Risco(models.TextChoices):
        BAIXO = 'BAIXO', 'Dentro do normal'
        MODERADO = 'MODERADO', 'Atenção'
        ALTO = 'ALTO', 'Risco de mastite subclínica'

    animal = models.ForeignKey(
        Animal,
        on_delete=models.CASCADE,
        related_name='registros_ccs',
    )
    valor_ccs = models.PositiveIntegerField(help_text="Contagem de Células Somáticas (células/mL)")
    data_coleta = models.DateField()
    laboratorio = models.CharField(max_length=150, blank=True)
    observacoes = models.TextField(blank=True)
    criado_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-data_coleta', '-criado_em']
        verbose_name = 'Registro de CCS'
        verbose_name_plural = 'Registros de CCS'

    @property
    def risco(self):
        # Faixas de referência comumente usadas na pecuária leiteira para
        # triagem de mastite subclínica a partir da CCS (células/mL).
        if self.valor_ccs > 400_000:
            return self.Risco.ALTO
        if self.valor_ccs > 200_000:
            return self.Risco.MODERADO
        return self.Risco.BAIXO

    def __str__(self):
        return f"{self.animal.brinco} - {self.valor_ccs} céls/mL ({self.data_coleta})"