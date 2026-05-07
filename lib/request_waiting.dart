import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'passenger_home.dart';
import 'ride_confirmed.dart';

class RequestWaitingScreen extends StatefulWidget {
  final String requestId;
  final dynamic ride;

  const RequestWaitingScreen({super.key, required this.requestId, required this.ride});

  @override
  State<RequestWaitingScreen> createState() => _RequestWaitingScreenState();
}

class _RequestWaitingScreenState extends State<RequestWaitingScreen> {
  int _timeLeft = 30;
  Timer? _countdownTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startTimers();
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
    final url = Uri.parse("http://192.168.31.159:5000/api/rides/request-status/${widget.requestId}");
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
      final url = Uri.parse("http://192.168.31.159:5000/api/rides/ride/$rideId");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final rideData = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideConfirmedScreen(
                rideId: rideId,
                rideData: rideData,
              ),
            ),
          );
        }
      } else {
        // Fallback: navigate with basic ride data
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideConfirmedScreen(
                rideId: rideId,
                rideData: widget.ride,
              ),
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
            builder: (context) => RideConfirmedScreen(
              rideId: rideId,
              rideData: widget.ride,
            ),
          ),
        );
      }
    }
  }

  void _handleRejection() {
    _cancelTimers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No driver is available on this route. Try again after some time.")),
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
        const SnackBar(content: Text("No driver is available on this route. Try again after some time.")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 60, color: Colors.orange),

            const SizedBox(height: 20),

            const Text(
              "Request Sent!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Waiting for driver & co-riders to accept",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // Timer UI
            Container(
              height: 80,
              width: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange, width: 3),
              ),
              child: Text(
                "$_timeLeft",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            const Text("Expires soon", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),

            // Fare Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text("Your fare"), Text("₹--")],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text("Pickup ETA"), Text("--")],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
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
                child: const Text("Cancel Request"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
