import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'live_traker.dart';
import 'passenger_home.dart';

class RideConfirmedScreen extends StatefulWidget {
  final String rideId;
  final dynamic rideData;

  const RideConfirmedScreen({super.key, required this.rideId, required this.rideData});

  @override
  State<RideConfirmedScreen> createState() => _RideConfirmedScreenState();
}

class _RideConfirmedScreenState extends State<RideConfirmedScreen> {
  IO.Socket? socket;
  String driverName = "--";
  String vehicleName = "--";
  String source = "--";
  String destination = "--";
  bool rideStarted = false;

  @override
  void initState() {
    super.initState();
    _extractRideData();
    _connectSocket();
  }

  void _extractRideData() {
    final ride = widget.rideData;
    if (ride != null) {
      // Handle populated driverId (object) or plain string
      if (ride['driverId'] is Map) {
        driverName = ride['driverId']['name'] ?? '--';
        vehicleName = ride['driverId']['vehicleName'] ?? '--';
      }
      source = ride['source'] ?? '--';
      destination = ride['destination'] ?? '--';
    }
  }

  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    socket = IO.io('http://192.168.31.159:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('RideConfirmed: Socket connected');
      socket!.emit('join_room', {'userId': userId, 'role': 'Passenger'});
    });

    // Listen for ride started event
    socket!.on('ride_started', (data) {
      print('Ride started event received: $data');
      if (mounted) {
        setState(() {
          rideStarted = true;
        });
        _navigateToTracking();
      }
    });

    socket!.onDisconnect((_) {
      print('RideConfirmed: Socket disconnected');
    });
  }

  void _navigateToTracking() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LiveTrackingScreen(
            rideId: widget.rideId,
            rideData: widget.rideData,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Column(
        children: [
          // 🔹 Top Map UI (No real map)
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            color: const Color(0xFFE5EAE7),
            child: const Center(
              child: Icon(Icons.location_pin, size: 40, color: Colors.green),
            ),
          ),

          // 🔹 Bottom Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "✓ Ride confirmed! Driver is on the way",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Driver Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(vehicleName, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildAction(Icons.call, "Call"),
                            buildAction(Icons.chat, "Chat"),
                            buildAction(Icons.share, "Share"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ride Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [const Text("From"), Text(source)],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [const Text("To"), Text(destination)],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [Text("Status"), Text("Waiting for driver to start")],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Track Button (manual fallback)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        _navigateToTracking();
                      },
                      child: const Text("Track Live →"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAction(IconData icon, String label) {
    return Column(
      children: [Icon(icon), const SizedBox(height: 5), Text(label)],
    );
  }
}
