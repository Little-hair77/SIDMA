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