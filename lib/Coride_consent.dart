import 'package:flutter/material.dart';
import 'dart:async';

class CoRideConsentScreen extends StatefulWidget {
  final String requesterName;
  final String dropLocation;
  final String requestId;
  final Function(bool accepted)? onResponded;

  const CoRideConsentScreen({
    super.key,
    required this.requesterName,
    required this.dropLocation,
    required this.requestId,
    this.onResponded,
  });

  @override
  State<CoRideConsentScreen> createState() => _CoRideConsentScreenState();
}

class _CoRideConsentScreenState extends State<CoRideConsentScreen> {
  int _timeLeft = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() { _timeLeft--; });
      } else {
        timer.cancel();
        // Auto-accept after timeout (driver is the gate, not passenger)
        widget.onResponded?.call(true);
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Someone wants to share your ride",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "You'll save more by sharing!",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // Passenger Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFEF3C7),
                  child: Text(
                    widget.requesterName.isNotEmpty ? widget.requesterName[0].toUpperCase() : "?",
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.requesterName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Drop: ${widget.dropLocation.isNotEmpty ? widget.dropLocation : '--'}",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Fare Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("You save", style: TextStyle(fontSize: 14)),
                Text(
                  "₹48",
                  style: TextStyle(
                    color: Color(0xFF1A9E6E),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Timer
          Container(
            height: 56,
            width: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
            ),
            child: Text(
              "$_timeLeft",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 6),
          Text("Auto-accepts in $_timeLeft s", style: const TextStyle(color: Colors.grey, fontSize: 11)),

          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    widget.onResponded?.call(false);
                    Navigator.pop(context);
                  },
                  child: const Text("Decline"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A9E6E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    widget.onResponded?.call(true);
                    Navigator.pop(context);
                  },
                  child: const Text("Accept & Save ₹48"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
