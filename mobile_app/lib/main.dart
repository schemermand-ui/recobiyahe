import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const RecoBiyaheApp());
}

class RecoBiyaheApp extends StatelessWidget {
  const RecoBiyaheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'RecoBiyahe', home: const MapScreen());
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LatLng myLocation = LatLng(14.5547, 121.0244);
  List<Marker> vehicleMarkers = [];
  bool isLoading = true;

  LatLng? destination;
  bool isFetchingEta = false;
  String? etaResultText;
  String? etaErrorText;

  @override
  void initState() {
    super.initState();
    fetchNearbyVehicles();
  }

  Future<void> fetchNearbyVehicles() async {
    final url = Uri.parse(
      'http://10.0.2.2:8000/vehicles/nearby/?lat=${myLocation.latitude}&lng=${myLocation.longitude}&radius_km=5',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          vehicleMarkers = data.map((vehicle) {
            final lat = vehicle['current_lat'] as double;
            final lng = vehicle['current_lng'] as double;
            return Marker(
              point: LatLng(lat, lng),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.directions_bus,
                color: Colors.blue,
                size: 36,
              ),
            );
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Failed to fetch vehicles: $e');
    }
  }

  Future<void> fetchEta(LatLng dest) async {
    setState(() {
      isFetchingEta = true;
      etaResultText = null;
      etaErrorText = null;
    });

    final url = Uri.parse(
      'http://10.0.2.2:8000/vehicles/eta/'
      '?origin_lat=${myLocation.latitude}&origin_lng=${myLocation.longitude}'
      '&dest_lat=${dest.latitude}&dest_lng=${dest.longitude}',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          etaResultText =
              '${data['distance_km']} km \u2022 ${data['duration_min']} min';
          isFetchingEta = false;
        });
      } else {
        setState(() {
          etaErrorText = 'Server error (${response.statusCode})';
          isFetchingEta = false;
        });
      }
    } catch (e) {
      setState(() {
        etaErrorText = 'Failed to fetch ETA';
        isFetchingEta = false;
      });
      debugPrint('ETA fetch failed: $e');
    }
  }

  void onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => destination = point);
    fetchEta(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RecoBiyahe - Nearby Vehicles')),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: myLocation,
                    initialZoom: 14,
                    onTap: onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobile_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: myLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                        ...vehicleMarkers,
                        if (destination != null)
                          Marker(
                            point: destination!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.flag,
                              color: Colors.green,
                              size: 36,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

          // ETA info card, floats at the bottom
          if (destination != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isFetchingEta
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Calculating ETA...'),
                          ],
                        )
                      : Text(
                          etaErrorText ?? etaResultText ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchNearbyVehicles,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
