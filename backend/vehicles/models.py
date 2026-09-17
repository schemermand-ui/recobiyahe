from django.db import models

# Create your models here.
class Vehicle(models.Model):
    class VehicleType(models.TextChoices):
        JEEPNEY = 'jeepney', 'Jeepney'
        TRICYCLE = 'tricycle', 'Tricycle'
        
    class Status(models.TextChoices):
        AVAILABLE = 'available', 'Available'
        ON_ROUTE = 'on_route', 'On route'
        OFFLINE = 'offline', 'Offline'
        
    plate_number = models.CharField(max_length=20, unique=True)
    vehicle_type = models.CharField(max_length=20, choices=VehicleType.choices)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OFFLINE)
    
    current_lat = models.FloatField(null=True, blank=True)
    current_lng = models.FloatField(null=True, blank=True)
    last_updated = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.plate_number} ({self.vehicle_type})"