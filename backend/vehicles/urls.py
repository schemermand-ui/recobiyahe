from django.urls import path
from .views import nearby_vehicles

urlpatterns = [
    path('nearby/', nearby_vehicles, name='vehicles_nearby'),
]
