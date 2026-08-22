from django.db import models

# Create your models here.
class Tratamento (models.Model):
    """Registra um período de tratamento (ex: antibiótico) e a 
    data até quando o leite deve ficar em carência"""
    animal = models.ForeignKey('rebanho.Animal', on_delete=models.CASCADE, related_name='tratamentos')
    medicamento = models.CharField(max_length=100, blank=True)
    data_inicio = models.DateField()
    data_fim_carencia = models.DateField(help_text="Data até quando o leite não deve ser misturado ao tanque")
    observacoes = models.TextField(blank=True)
    criado_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-data_fim_carencia']
        verbose_name = 'Tratamento'
        verbose_name_plural = 'Tratamentos'

    def __str__(self):
        return f"{self.animal.brinco} - {self.medicamento} (até {self.data_fim_carencia:%d/%m/%Y})"