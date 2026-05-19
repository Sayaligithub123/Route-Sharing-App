import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'RideComplete.dart';
import 'Coride_consent.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String rideId;
  final dynamic rideData;

  const LiveTrackingScreen({super.key, required this.rideId, required this.rideData});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  IO.Socket? socket;
  String driverName = "--";
  String source = "--";
  String destination = "--";
  double? driverLat;
  double? driverLng;
  String? currentUserId;

  // Real passenger data from backend
  List<Map<String, dynamic>> passengers = [];
  Map<String, dynamic>? driverInfo;
  bool isLoadingPassengers = true;

  @override
  void initState() {
    super.initState();
    _extractRideData();
    _loadUserId();
    _fetchPassengers();
    _connectSocket();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId');
  }

  void _extractRideData() {
    final ride = widget.rideData;
    if (ride == null) return;
    if (ride['driverId'] is Map) {
      driverName = ride['driverId']['name'] ?? '--';
    }
    source = ride['source'] ?? '--';
    destination = ride['destination'] ?? '--';
    if (ride['driverLocation'] != null) {
      driverLat = (ride['driverLocation']['lat'] as num?)?.toDouble();
      driverLng = (ride['driverLocation']['lng'] as num?)?.toDouble();
    }
  }

  Future<void> _fetchPassengers() async {
    try {
      final url = Uri.parse("http://192.168.31.52:5000/api/rides/ride/${widget.rideId}/passengers");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            passengers = List<Map<String, dynamic>>.from(data['passengers'] ?? []);
            if (data['driver'] != null) {
              driverInfo = Map<String, dynamic>.from(data['driver']);
              driverName = driverInfo!['name'] ?? '--';
            }
            isLoadingPassengers = false;
          });
        }
      } else {
        if (mounted) setState(() { isLoadingPassengers = false; });
      }
    } catch (e) {
      print("Error fetching passengers: $e");
      if (mounted) setState(() { isLoadingPassengers = false; });
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
      socket!.emit('join_room', {'userId': userId, 'role': 'Passenger'});
    });

    socket!.on('location_update', (data) {
      if (mounted && data['location'] != null) {
        setState(() {
          driverLat = (data['location']['lat'] as num?)?.toDouble();
          driverLng = (data['location']['lng'] as num?)?.toDouble();
        });
      }
    });

    socket!.on('ride_completed', (data) {
      if (mounted) _navigateToComplete();
    });

    // Listen for new co-ride request (someone wants to join your shared ride)
    socket!.on('coride_request', (data) {
      if (mounted) {
        _showCorideConsentModal(data);
      }
    });

    // Listen for co-ride accepted (a new passenger joined the ride)
    socket!.on('coride_accepted', (data) {
      if (mounted) {
        // Refresh passenger list from backend
        _fetchPassengers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${data['newPassengerName'] ?? 'A passenger'} joined your ride!"),
            backgroundColor: const Color(0xFF1A9E6E),
          ),
        );
      }
    });
  }

  void _showCorideConsentModal(dynamic data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CoRideConsentScreen(
        requesterName: data['requesterName'] ?? 'Someone',
        dropLocation: data['dropLocation'] ?? '',
        requestId: data['requestId'] ?? '',
        onResponded: (accepted) {
          // Passenger consent is informational — driver is the gate
        },
      ),
    );
  }

  void _navigateToComplete() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideCompleteScreen(rideData: widget.rideData),
      ),
    );
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSharedRide = passengers.length > 1;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Map area
          Container(
            height: MediaQuery.of(context).size.height * 0.40,
            decoration: const BoxDecoration(color: Color(0xFFE5EAE7)),
            child: Stack(
              children: [
                // Grid lines for map effect
                Positioned(
                  top: 0, bottom: 0, left: 150,
                  child: Container(width: 6, color: Colors.white),
                ),
                Positioned(
                  top: 110, left: 0, right: 0,
                  child: Container(height: 6, color: Colors.white),
                ),
                // Car icon
                Positioned(
                  top: 97, left: 138,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A9E6E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text("🚗", style: TextStyle(fontSize: 18))),
                  ),
                ),
                // Destination pin
                Positioned(
                  bottom: 40, left: 210,
                  child: const Icon(Icons.location_on, color: Color(0xFF1A9E6E), size: 28),
                ),
                // Live badge
                Positioned(
                  top: 50, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                    child: const Text("• Live", style: TextStyle(color: Colors.white)),
                  ),
                ),
                // Passenger count badge
                if (isSharedRide)
                  Positioned(
                    top: 50, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A9E6E).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${passengers.length} passengers aboard",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shared ride banner
                  if (isSharedRide)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A9E6E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A9E6E).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text("✓ ", style: TextStyle(color: Color(0xFF1A9E6E), fontSize: 16)),
                          Text(
                            "Shared ride active · You're saving ₹${passengers.length > 1 ? 48 * (passengers.length - 1) : 0}",
                            style: const TextStyle(
                              color: Color(0xFF1A9E6E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!isSharedRide)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "On your way",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Passenger cards row — REAL DATA
                  if (isLoadingPassengers)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildPassengerCardsRow(),

                  const SizedBox(height: 16),

                  // Driver info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Driver", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            const Text("ETA to your drop", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  driverName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Text(" · 4.8 ", style: TextStyle(fontSize: 13)),
                                const Text("⭐", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text("~11 min", style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SOS Emergency Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("🆘 ", style: TextStyle(fontSize: 16)),
                          Text("SOS Emergency", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
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

  Widget _buildPassengerCardsRow() {
    if (passengers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Color palette for passenger avatars
    final List<Map<String, Color>> colorPalette = [
      {'bg': const Color(0xFFEDE9FE), 'fg': const Color(0xFF5B21B6)},
      {'bg': const Color(0xFFFEF3C7), 'fg': const Color(0xFF92400E)},
      {'bg': const Color(0xFFDCFCE7), 'fg': const Color(0xFF166534)},
      {'bg': const Color(0xFFDBEAFE), 'fg': const Color(0xFF1E40AF)},
    ];

    final List<String> dropLabels = ["1st drop", "2nd drop", "3rd drop", "4th drop"];

    return Row(
      children: [
        // Passenger cards
        ...passengers.asMap().entries.map((entry) {
          final index = entry.key;
          final passenger = entry.value;
          final name = passenger['name'] ?? 'Passenger';
          final dropLoc = passenger['dropLocation'] ?? '';
          final isCurrentUser = currentUserId != null && passenger['_id'] == currentUserId;
          final colors = colorPalette[index % colorPalette.length];
          final initials = _getInitials(name);

          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors['bg'],
                    child: Text(
                      isCurrentUser ? "You" : initials,
                      style: TextStyle(
                        color: colors['fg'],
                        fontSize: isCurrentUser ? 9 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCurrentUser ? "You (${name.split(' ').first})" : "${name.split(' ').first} ${name.length > 1 ? '${name.split(' ').last[0]}.' : ''}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dropLoc.isNotEmpty ? dropLoc : destination,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors['bg'],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      index < dropLabels.length ? dropLabels[index] : "${index + 1}th drop",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: colors['fg'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // "You pay" card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
              ],
            ),
            child: Column(
              children: [
                const Text("You pay", style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  "₹${passengers.length > 1 ? 82 : 130}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A9E6E),
                  ),
                ),
                if (passengers.length > 1)
                  Text(
                    "saved ₹${48 * (passengers.length - 1)}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : "?";
  }
}
