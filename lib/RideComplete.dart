import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_route_app/passenger_home.dart';

class RideCompleteScreen extends StatefulWidget {
  final dynamic rideData;

  const RideCompleteScreen({super.key, this.rideData});

  @override
  State<RideCompleteScreen> createState() => _RideCompleteScreenState();
}

class _RideCompleteScreenState extends State<RideCompleteScreen> {
  String? currentUserId;
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndRideData();
  }

  Future<void> _loadUserAndRideData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId');
      _isLoading = false;
    });
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return "Terrible";
      case 2:
        return "Bad";
      case 3:
        return "Average";
      case 4:
        return "Very Good";
      case 5:
        return "Excellent!";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    String source = '--';
    String destination = '--';
    String driverName = '--';
    int sharedFare = 0;
    int soloFare = 0;
    int savings = 0;
    double distance = 0.0;
    int coRidersCount = 0;

    if (widget.rideData != null) {
      final ride = widget.rideData;
      
      // Standard fallback values if no passenger-specific match
      source = ride['source'] ?? '--';
      destination = ride['destination'] ?? '--';
      
      if (ride['driverId'] is Map) {
        driverName = ride['driverId']['name'] ?? '--';
      } else {
        driverName = 'Driver';
      }

      // Check passenger list for active count
      final passengerList = ride['passengers'] is List ? ride['passengers'] as List : [];
      coRidersCount = passengerList.length;

      // Extract specific passenger details
      final dropList = ride['passengerDropLocations'] is List
          ? ride['passengerDropLocations'] as List
          : [];

      final myInfo = dropList.firstWhere(
        (p) => currentUserId != null && p['passengerId'] != null &&
            (p['passengerId'] is Map
                ? p['passengerId']['_id'].toString() == currentUserId
                : p['passengerId'].toString() == currentUserId),
        orElse: () => null,
      );

      if (myInfo != null) {
        source = myInfo['pickupLocation'] ?? source;
        destination = myInfo['dropLocation'] ?? destination;
        sharedFare = (myInfo['sharedFare'] as num?)?.toInt() ?? 0;
        soloFare = (myInfo['soloFare'] as num?)?.toInt() ?? 0;
        savings = (myInfo['savings'] as num?)?.toInt() ?? 0;
        distance = (myInfo['distance'] as num?)?.toDouble() ?? 0.0;
      } else {
        // Grab the first passenger drop location as fallback
        if (dropList.isNotEmpty) {
          final first = dropList.first;
          source = first['pickupLocation'] ?? source;
          destination = first['dropLocation'] ?? destination;
          sharedFare = (first['sharedFare'] as num?)?.toInt() ?? 0;
          soloFare = (first['soloFare'] as num?)?.toInt() ?? 0;
          savings = (first['savings'] as num?)?.toInt() ?? 0;
          distance = (first['distance'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }

    // Estimate duration: ~2.5 mins per km
    final int estimatedDuration = distance > 0 ? (distance * 2.5).round() : 15;

    // Calculate dynamic discount percentage shown in the pill
    final double discountPercent = soloFare > 0 ? (savings / soloFare) * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              
              // 🎉 Animated-style Success Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 64,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Trip Completed!",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Thank you for sharing your ride & saving emissions",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 💰 Premium Receipt Glassmorphism-style Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    )
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Receipt Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "FARES SUMMARY",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (savings > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${discountPercent.toStringAsFixed(0)}% SPLIT DISCOUNT",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Fare Breakdown Elements
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Base Solo Fare
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Original Solo Fare",
                                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                              ),
                              Text(
                                "₹$soloFare",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Co-ride split savings
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Co-Riding Savings",
                                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                              ),
                              Text(
                                "- ₹$savings",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                          ),

                          // Final amount paid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Amount Paid",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "₹$sharedFare",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 📊 Detailed Trip Metadata Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "JOURNEY DETAILS",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 18),
                    
                    // Route Row
                    _buildDetailRow(
                      Icons.location_on_rounded, 
                      "Pickup", 
                      source, 
                      iconColor: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDetailRow(
                      Icons.navigation_rounded, 
                      "Destination", 
                      destination, 
                      iconColor: const Color(0xFFEF4444),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    ),

                    // Metadata metrics
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            Icons.speed_rounded,
                            "${distance.toStringAsFixed(1)} km",
                            "Distance",
                          ),
                        ),
                        Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                        Expanded(
                          child: _buildMetricItem(
                            Icons.timer_rounded,
                            "$estimatedDuration min",
                            "Duration",
                          ),
                        ),
                        Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                        Expanded(
                          child: _buildMetricItem(
                            Icons.person_rounded,
                            driverName,
                            "Driver",
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ⭐ Rating and Comment Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        "RATE YOUR EXPERIENCE",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Rating stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isFilled = starValue <= _rating;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = starValue;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 40,
                              color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _getRatingText(_rating),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Comments Box
                    TextField(
                      controller: _commentController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Leave feedback (optional)...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ✅ Submit & Done Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PassengerHomeScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Submit & Back to Home",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {required Color iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
