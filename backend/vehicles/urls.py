from django.urls import path
from .views import nearby_vehicles, eta

urlpatterns = [
    path('nearby/', nearby_vehicles, name='vehicles_nearby'),
    path('eta/', eta, name='vehicles-eta'),
]
