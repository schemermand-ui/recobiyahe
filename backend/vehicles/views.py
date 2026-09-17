import math
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Vehicle
from .serializer import VehicleSerializer

def haversine_km(lat1, lng1, lat2, lng2):
    """Straight-line distance between two coordinates, in kilometers"""
    R = 6371 # Earth's radius in KM
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (math.sin(dlat / 2) ** 2
         * math.cos(math.radians(lat1)) * math.cos(math.radians(lat2))
         * math.sin(dlng / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

@api_view(['GET'])
def nearby_vehicles(request):
    lat = request.query_params.get('lat')
    lng = request.query_params.get('lng')
    radius_km = float(request.query_params.get('radius_km', 2))
    
    if lat is None or lng is None:
        return Response({'error': 'lat and lng query params are require'}, status=400)
    
    lat, lng = float(lat), float(lng)
    
    results = []
    for vehicle in Vehicle.objects.filter(status='available', current_lat__isnull=False):
        distance = haversine_km(lat, lng, vehicle.current_lat, vehicle.current_lng)
        if distance <= radius_km:
            vehicle.distance_km = round(distance, 2)
            results.append(vehicle)
            
    results.sort(key=lambda v: v.distance_km)
    serializer = VehicleSerializer(results, many=True)
    return Response(serializer.data)