from rest_framework import serializers
from .models import Vehicle

class VehicleSerializer(serializers.ModelSerializer):
    distance_km = serializers.FloatField(read_only=True, required=False)
    
    class Meta:
        model = Vehicle
        fields = [
            'id', 'plate_number', 'vehicle_type', 'status',
            'current_lat', 'current_lng', 'distance_km', 'last_updated',
        ]