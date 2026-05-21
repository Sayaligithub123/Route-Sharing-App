import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Driver_joiningRequest.dart';
import 'Driver_homepage.dart';

class ActiveRideScreen extends StatefulWidget {
  final String rideId;
  final String source;
  final String destination;

  const ActiveRideScreen({
    super.key,
    required this.rideId,
    required this.source,
    required this.destination,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  IO.Socket? socket;
  bool rideStarted = false;

  // Real passenger data from backend
  List<Map<String, dynamic>> passengers = [];
  bool isLoadingPassengers = true;

  // Distance calculation
  String routeDistance = "";
  String routeDuration = "";
  bool isCalculatingRoute = true;

  @override
  void initState() {
    super.initState();
    _fetchPassengers();
    _connectSocket();
    _calculateRouteInfo();
  }

  Future<void> _calculateRouteInfo() async {
    final info = await RouteService.calculateRoute(widget.source, widget.destination);
    if (mounted) {
      setState(() {
        if (info != null) {
          routeDistance = "${info['distance'].toStringAsFixed(1)} km";
          routeDuration = "${info['duration'].toStringAsFixed(0)} mins";
        } else {
          routeDistance = "Could not calculate";
          routeDuration = "N/A";
        }
        isCalculatingRoute = false;
      });
    }
  }

  Future<void> _fetchPassengers() async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/rides/ride/${widget.rideId}/passengers",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            passengers = List<Map<String, dynamic>>.from(
              data['passengers'] ?? [],
            );
            isLoadingPassengers = false;
          });
        }
      } else {
        if (mounted)
          setState(() {
            isLoadingPassengers = false;
          });
      }
    } catch (e) {
      print("Error fetching passengers: $e");
      if (mounted)
        setState(() {
          isLoadingPassengers = false;
        });
    }
  }

  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();

    socket!.onConnect((_) {
      print('Driver ActiveRide: Socket connected (id=${socket!.id})');
      socket!.emit('join_room', {'userId': userId, 'role': 'Driver'});
      print('Driver ActiveRide: Emitted join_room for driver_$userId');
    });

    // Listen for new ride requests from passengers
    socket!.on('new_request', (data) {
      print('Driver ActiveRide: new_request received: $data');
      if (mounted) {
        final request = data['request'];
        _fetchPassengerAndShowModal(request);
      }
    });

    socket!.onConnectError((error) {
      print('Driver ActiveRide: Socket connection error: $error');
    });

    socket!.onReconnect((_) {
      print('Driver ActiveRide: Socket reconnected, re-joining room');
      socket!.emit('join_room', {'userId': userId, 'role': 'Driver'});
    });

    socket!.onDisconnect((_) {
      print('Driver ActiveRide: Socket disconnected');
    });
  }

  Future<void> _fetchPassengerAndShowModal(dynamic request) async {
    final requestId = request['_id'] ?? '';
    final passengerId = request['passengerId'] ?? '';

    // Fetch passenger details
    String passengerName = 'Passenger';
    String passengerPhone = '--';
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/users/$passengerId",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        passengerName = user['name'] ?? 'Passenger';
        passengerPhone = user['phone'] ?? '--';
      }
    } catch (e) {
      print("Error fetching passenger: $e");
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => JoinRequestModal(
          requestId: requestId,
          name: passengerName,
          seats: "1",
          phone: passengerPhone,
          onResponded: (accepted) {
            if (accepted) {
              // Refresh passenger list from backend to get real data
              _fetchPassengers();
            }
          },
        ),
      );
    }
  }

  Future<void> _startTrip() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/rides/start-trip");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"rideId": widget.rideId}),
      );
      if (response.statusCode == 200) {
        setState(() {
          rideStarted = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Trip started! Passengers notified.")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Network error: $e")));
      }
    }
  }

  Future<void> _completeRide() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/rides/complete-ride");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"rideId": widget.rideId}),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ride completed! Passengers notified."),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Network error: $e")));
      }
    }
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  // Color palette for passenger avatars
  final List<Map<String, Color>> _colorPalette = [
    {'bg': const Color(0xFFEDE9FE), 'fg': const Color(0xFF5B21B6)},
    {'bg': const Color(0xFFFEF3C7), 'fg': const Color(0xFF92400E)},
    {'bg': const Color(0xFFDCFCE7), 'fg': const Color(0xFF166534)},
    {'bg': const Color(0xFFDBEAFE), 'fg': const Color(0xFF1E40AF)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Column(
        children: [
          // Map UI
          Container(
            height: MediaQuery.of(context).size.height * 0.40,
            color: const Color(0xFFE5EAE7),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 150,
                  child: Container(width: 6, color: Colors.white),
                ),
                Positioned(
                  top: 110,
                  left: 0,
                  right: 0,
                  child: Container(height: 6, color: Colors.white),
                ),
                Positioned(
                  top: 97,
                  left: 138,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A9E6E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text("🚗", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 210,
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF1A9E6E),
                    size: 28,
                  ),
                ),
                // Passenger count badge
                if (passengers.isNotEmpty)
                  Positioned(
                    top: 50,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A9E6E).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${passengers.length} passenger${passengers.length > 1 ? 's' : ''} aboard",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom panel
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route info
                  Text(
                    "Heading to ${widget.destination}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "From ${widget.source}",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 10),

                  // 🔹 Distance & Duration display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A9E6E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1A9E6E).withOpacity(0.3)),
                    ),
                    child: isCalculatingRoute
                        ? Row(
                            children: const [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Color(0xFF1A9E6E),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Calculating route...",
                                style: TextStyle(fontSize: 12, color: Color(0xFF1A9E6E)),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(Icons.route, size: 18, color: Color(0xFF1A9E6E)),
                              const SizedBox(width: 8),
                              Text(
                                "🛣️ $routeDistance",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A9E6E),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time, size: 18, color: Color(0xFF1A9E6E)),
                              const SizedBox(width: 4),
                              Text(
                                "⏱️ $routeDuration",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A9E6E),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Passenger cards — REAL DATA
                  if (isLoadingPassengers)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _buildPassengerCards(),

                  const SizedBox(height: 12),

                  // Seat grid
                  _buildSeatGrid(),

                  const SizedBox(height: 12),

                  // Request banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: passengers.isNotEmpty
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      passengers.isEmpty
                          ? "No passengers yet — waiting for join requests"
                          : "${passengers.length} passenger(s) joined",
                      style: TextStyle(
                        color: passengers.isNotEmpty
                            ? const Color(0xFF1A9E6E)
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Start Trip button (only if not started yet)
                  if (!rideStarted)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A9E6E),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _startTrip,
                      child: const Text(
                        "Start Trip →",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  if (rideStarted) ...[
                    const Center(
                      child: Text(
                        "Trip is in progress",
                        style: TextStyle(
                          color: Color(0xFF1A9E6E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 10),

                  // Complete / End ride
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rideStarted
                          ? Colors.red[400]
                          : Colors.grey[300],
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _completeRide,
                    child: Text(
                      rideStarted ? "Complete Ride" : "End Ride Early",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildPassengerCards() {
    if (passengers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        ...passengers.asMap().entries.map((entry) {
          final index = entry.key;
          final p = entry.value;
          final name = p['name'] ?? 'Passenger';
          final drop = p['dropLocation'] ?? widget.destination;
          final colors = _colorPalette[index % _colorPalette.length];
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors['bg'],
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: colors['fg'],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${name.split(' ').first} ${name.split(' ').length > 1 ? '${name.split(' ').last[0]}.' : ''}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Drop: $drop",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
        // Earning card
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
                const Text(
                  "Earning",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${130 + (passengers.length > 1 ? 48 * (passengers.length - 1) : 0)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A9E6E),
                  ),
                ),
                const Text(
                  "total",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatGrid() {
    // Build seat tiles: "You" (driver) + passengers + free seats
    List<Widget> seatTiles = [];
    seatTiles.add(_seatTile("You", const Color(0xFF374151), Colors.white));

    for (int i = 0; i < passengers.length; i++) {
      final name = passengers[i]['name'] ?? 'Pax';
      final colors = _colorPalette[i % _colorPalette.length];
      seatTiles.add(
        _seatTile(name.split(' ').first, colors['bg']!, colors['fg']!),
      );
    }

    // Remaining free seats (assume max 4 total seats)
    final int maxSeats = 4;
    final int freeSeats = maxSeats - 1 - passengers.length; // -1 for driver
    for (int i = 0; i < freeSeats && i < 3; i++) {
      seatTiles.add(
        _seatTile("Free", const Color(0xFFF3F4F6), const Color(0xFF9CA3AF)),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: seatTiles,
    );
  }

  Widget _seatTile(String label, Color bg, Color fg) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
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
