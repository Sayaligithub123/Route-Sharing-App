import 'package:flutter/material.dart';
import 'request_waiting.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RidesScreen extends StatefulWidget {
  final String source;
  final String destination;
  const RidesScreen({super.key, required this.source, required this.destination});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  List<dynamic> rides = [];
  bool isLoading = true;
  String? requestingRideId;

  @override
  void initState() {
    super.initState();
    fetchRides();
  }

  Future<void> fetchRides() async {
    final url = Uri.parse("http://192.168.31.52:5000/api/rides/search?source=${widget.source}&destination=${widget.destination}");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          rides = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching rides: ${response.body}")));
      }
    } catch(e) {
      setState(() { isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Rides on your route"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Route Summary Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${widget.source} → ${widget.destination}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 🔹 Filter Chips
            Row(
              children: [
                buildChip("All"),
                const SizedBox(width: 10),
                buildChip("Closest"),
                const SizedBox(width: 10),
                buildChip("Cheapest"),
              ],
            ),

            const SizedBox(height: 20),

            // Ride list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : rides.isEmpty
                      ? const Center(child: Text("No rides available yet"))
                      : ListView.builder(
                          itemCount: rides.length,
                          itemBuilder: (context, index) {
                            return buildRideCard(context, rides[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChip(String label) {
    return Chip(label: Text(label), backgroundColor: Colors.grey[200]);
  }

  Widget buildRideCard(BuildContext context, dynamic ride) {
    final driver = ride['driverId'] ?? {};
    final driverName = driver['name'] ?? 'Unknown Driver';
    final vehicle = driver['vehicleName'] ?? 'Vehicle';
    final seats = ride['availableSeats'] ?? 0;
    final currentPassengers = ride['currentPassengerCount'] ?? 0;
    final totalSeats = seats + currentPassengers;
    final rideStatus = ride['status'] ?? 'active';
    final passengers = ride['passengers'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                driverName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Ride status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rideStatus == 'in_progress'
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rideStatus == 'in_progress' ? "In Progress" : "Active",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: rideStatus == 'in_progress' ? Colors.orange : Colors.green,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Passenger count & vehicle info
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                "$currentPassengers/$totalSeats passengers",
                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(vehicle, style: TextStyle(color: Colors.grey[700])),
            ],
          ),

          // Show existing passenger names if any
          if (passengers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: passengers.map<Widget>((p) {
                final name = p is Map ? (p['name'] ?? '?') : '?';
                return Chip(
                  label: Text(name, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: requestingRideId == ride['_id'] ? null : () async {
                setState(() {
                  requestingRideId = ride['_id'];
                });
                
                final prefs = await SharedPreferences.getInstance();
                final passengerId = prefs.getString('userId');
                
                if (passengerId == null) {
                  setState(() { requestingRideId = null; });
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: User ID not found")));
                  return;
                }
                
                final url = Uri.parse("http://192.168.31.52:5000/api/rides/request");
                try {
                  final response = await http.post(
                    url,
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "rideId": ride['_id'],
                      "passengerId": passengerId,
                      "pickupLocation": widget.source,
                      "dropLocation": widget.destination,
                    }),
                  );
                  
                  setState(() { requestingRideId = null; });
                  
                  if (response.statusCode == 201 || response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestWaitingScreen(
                            requestId: data['request']['_id'],
                            ride: ride,
                          ),
                        ),
                      );
                    }
                  } else {
                    final errorData = jsonDecode(response.body);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${errorData['error'] ?? response.body}")));
                  }
                } catch(e) {
                  setState(() { requestingRideId = null; });
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network Error: $e")));
                }
              },
              child: requestingRideId == ride['_id']
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(seats > 0 ? "Request to Join ($seats seats left)" : "Full"),
            ),
          ),
        ],
      ),
    );
  }
}
