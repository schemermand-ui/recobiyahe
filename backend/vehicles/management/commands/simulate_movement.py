import time
from django.core.management.base import BaseCommand
from vehicles.models import Vehicle


class Command(BaseCommand):
    help = 'Simulates a vehicle moving in a straight line between two points over time.'

    def add_arguments(self, parser):
        parser.add_argument('plate_number', type=str, help='Plate number of the vehicle to move')
        parser.add_argument('--start-lat', type=float, required=True)
        parser.add_argument('--start-lng', type=float, required=True)
        parser.add_argument('--end-lat', type=float, required=True)
        parser.add_argument('--end-lng', type=float, required=True)
        parser.add_argument('--steps', type=int, default=20, help='Number of movement steps')
        parser.add_argument('--interval', type=float, default=2.0, help='Seconds between each step')

    def handle(self, *args, **options):
        plate_number = options['plate_number']
        start_lat = options['start_lat']
        start_lng = options['start_lng']
        end_lat = options['end_lat']
        end_lng = options['end_lng']
        steps = options['steps']
        interval = options['interval']

        try:
            vehicle = Vehicle.objects.get(plate_number=plate_number)
        except Vehicle.DoesNotExist:
            self.stderr.write(f"No vehicle found with plate number '{plate_number}'")
            return

        vehicle.status = Vehicle.Status.ON_ROUTE
        vehicle.save()

        self.stdout.write(f"Moving {plate_number} from ({start_lat}, {start_lng}) to ({end_lat}, {end_lng})...")

        for step in range(steps + 1):
            fraction = step / steps
            current_lat = start_lat + (end_lat - start_lat) * fraction
            current_lng = start_lng + (end_lng - start_lng) * fraction

            vehicle.current_lat = current_lat
            vehicle.current_lng = current_lng
            vehicle.save()

            self.stdout.write(f"Step {step}/{steps}: ({current_lat:.5f}, {current_lng:.5f})")
            time.sleep(interval)

        vehicle.status = Vehicle.Status.AVAILABLE
        vehicle.save()
        self.stdout.write(self.style.SUCCESS(f"{plate_number} finished route. Status set back to available."))