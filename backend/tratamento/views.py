from django.utils.dateparse import parse_date
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Animal

# Create your views here.
def calcular_carencia(a):
    tratamento_ativo = a.tratamentos.filter