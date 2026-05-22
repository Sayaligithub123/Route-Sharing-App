import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'passenger_home.dart';
import 'ride_confirmed.dart';
import 'services/api_config.dart';
import 'services/route_service.dart';

class RequestWaitingScreen extends StatefulWidget {
  final String requestId;
  final dynamic ride;

  const RequestWaitingScreen({
    super.key,
    required this.requestId,
    required this.ride,
  });

  @override
  State<RequestWaitingScreen> createState() => _RequestWaitingScreenState();
}

class _RequestWaitingScreenState extends State<RequestWaitingScreen> {
  int _timeLeft = 30;
  Timer? _countdownTimer;
  Timer? _pollingTimer;

  // Distance calculation
  String routeDistance = "";
  String routeDuration = "";
  bool isCalculatingRoute = true;

  @override
  void initState() {
    super.initState();
    _startTimers();
    _calculateRouteInfo();
  }

  Future<void> _calculateRouteInfo() async {
    final source = widget.ride['source'] ?? '';
    final destination = widget.ride['destination'] ?? '';
    if (source.isEmpty || destination.isEmpty) {
      setState(() { isCalculatingRoute = false; });
      return;
    }
    final info = await RouteService.calculateRoute(source, destination);
    if (mounted) {
      setState(() {
        if (info != null) {
          routeDistance = "${info['distance'].toStringAsFixed(1)} km";
          routeDuration = "${info['duration'].toStringAsFixed(0)} mins";
        } else {
          routeDistance = "N/A";
          routeDuration = "N/A";
        }
        isCalculatingRoute = false;
      });
    }
  }

  void _startTimers() {
    // 30 seconds countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _handleTimeout();
      }
    });

    // Poll status every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkRequestStatus();
    });
  }

  Future<void> _checkRequestStatus() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/rides/request-status/${widget.requestId}",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'accepted') {
          _cancelTimers();
          // Fetch full ride details before navigating
          await _navigateToConfirmed(data['rideId']);
        } else if (status == 'rejected') {
          _handleRejection();
        }
      }
    } catch (e) {
      print("Polling error: $e");
    }
  }

  Future<void> _navigateToConfirmed(dynamic rideIdData) async {
    // rideIdData can be a string or an object with _id
    String rideId;
    if (rideIdData is String) {
      rideId = rideIdData;
    } else if (rideIdData is Map) {
      rideId = rideIdData['_id'] ?? '';
    } else {
      rideId = widget.ride['_id'] ?? '';
    }

    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/rides/ride/$rideId",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final rideData = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RideConfirmedScreen(rideId: rideId, rideData: rideData),
            ),
          );
        }
      } else {
        // Fallback: navigate with basic ride data
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RideConfirmedScreen(rideId: rideId, rideData: widget.ride),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback on error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RideConfirmedScreen(rideId: rideId, rideData: widget.ride),
          ),
        );
      }
    }
  }

  void _handleRejection() {
    _cancelTimers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No driver is available on this route. Try again after some time.",
          ),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
        (route) => false,
      );
    }
  }

  void _handleTimeout() {
    _cancelTimers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No driver is available on this route. Try again after some time.",
          ),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
        (route) => false,
      );
    }
  }

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  double? _getDistanceValue() {
    if (routeDistance.contains(" km")) {
      return double.tryParse(routeDistance.replaceAll(" km", "").trim());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double? dist = _getDistanceValue();
    String fareText = "₹--";
    if (dist != null) {
      final currentPassengers = widget.ride['currentPassengerCount'] ?? 0;
      final prospectivePaxCount = currentPassengers + 1;
      final soloEst = (40 + 12 * dist).round();
      double discountFactor = 1.0;
      if (prospectivePaxCount == 2) {
        discountFactor = 0.70;
      } else if (prospectivePaxCount == 3) {
        discountFactor = 0.55;
      } else if (prospectivePaxCount >= 4) {
        discountFactor = 0.40;
      }
      final sharedEst = (soloEst * discountFactor).round();
      if (currentPassengers > 0) {
        fareText = "₹$sharedEst (Co-ride Split)";
      } else {
        fareText = "₹$soloEst (Solo)";
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                        strokeWidth: 3,
                      ),
                    ),
                    Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            spreadRadius: 8,
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "$_timeLeft",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  "Finding Your Ride...",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Connecting with drivers & co-riders on your route",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.blueGrey.shade100, width: 1.5),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Estimated Fare",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              fareText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Pickup ETA",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              "~3 mins",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "🛣️ Distance",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            isCalculatingRoute
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                    ),
                                  )
                                : Text(
                                    routeDistance,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "⏱️ Est. Travel Time",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            isCalculatingRoute
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                    ),
                                  )
                                : Text(
                                    routeDuration,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _cancelTimers();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PassengerHomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Cancel Request",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
