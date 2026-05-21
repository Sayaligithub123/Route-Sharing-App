import 'dart:convert';
import 'package:http/http.dart' as http;

class RouteService {
  // 1. Geocodes a text address (like "Pune") into latitude and longitude using OpenStreetMap's Nominatim
  static Future<Map<String, double>?> getCoordinates(String address) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1'
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'RouteSharingApp/1.0', // Nominatim requires a user-agent header
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lon = double.parse(data[0]['lon']);
          return {'latitude': lat, 'longitude': lon};
        }
      }
    } catch (e) {
      print("Geocoding error for '$address': $e");
    }
    return null;
  }

  // 2. Calculates driving distance and duration between two coordinates using OSRM
  static Future<Map<String, dynamic>?> getDrivingDistance(
    double startLat, double startLng, double endLat, double endLng) async {
    
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=false'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          // Distance in kilometers
          double distanceInKm = data['routes'][0]['distance'] / 1000.0;
          // Duration in minutes
          double durationInMinutes = data['routes'][0]['duration'] / 60.0;
          
          return {
            'distance': distanceInKm,
            'duration': durationInMinutes,
          };
        }
      }
    } catch (e) {
      print("OSRM Routing error: $e");
    }
    return null;
  }

  // 3. Helper to geocode and calculate route in one step
  static Future<Map<String, dynamic>?> calculateRoute(
      String sourceAddress, String destinationAddress) async {
    
    // Get start coordinates
    final startCoords = await getCoordinates(sourceAddress);
    if (startCoords == null) return null;

    // Get end coordinates
    final endCoords = await getCoordinates(destinationAddress);
    if (endCoords == null) return null;

    // Calculate distance and time
    return await getDrivingDistance(
      startCoords['latitude']!,
      startCoords['longitude']!,
      endCoords['latitude']!,
      endCoords['longitude']!,
    );
  }
}
